//
//  FasTOrderDetailsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsViewController.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTTicketPrinter.h"
#import "FasTLogEvent.h"
#import "FasTSeat.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTApi.h"
#import "FasTFormatter.h"

@import MBProgressHUD;

@interface FasTOrderDetailsViewController ()
{
    NSArray *_infoTableRows;
    NSDateFormatter *_dateFormatter;
    BOOL _selectAllTicketsToggle;
    NSObject *_ordersObserver;
    
    UIRefreshControl *_refresh;
}

- (void)update;
- (void)reload;
- (void)updateAfterTicketSelection;
- (void)showAlertForTicketActionWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(void))handler;
- (void)performApiAction:(SEL)apiSelector onTickets:(NSArray *)tickets;

@end

@implementation FasTOrderDetailsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _selectAllTicketsToggle = YES;
    }
    return self;
}

- (void)dealloc
{
    [_order release];
    [_highlightedTicketId release];
    [_dateFormatter release];
    [_ticketsPopoverBarButton release];
    [_refundBarButton release];
    [_refresh release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_order) {
        [self reload];
        self.navigationItem.title = [NSString stringWithFormat:self.navigationItem.title, _order.number];
    }
    
    _refresh = [[UIRefreshControl alloc] init];
    [_refresh addTarget:self action:@selector(update) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refresh];
    
    [self.tableView setEditing:YES animated:NO];
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _ordersObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"FasTUpdatedOrderInfo" object:nil queue:nil usingBlock:^(NSNotification *note) {
        FasTOrder *order = (FasTOrder *)note.userInfo[@"order"];
        if ([_order.orderId isEqualToString:order.orderId]) {
            self.order = order;
            [self reload];
            [self.tableView reloadData];
        }
    }];
    [_ordersObserver retain];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:_ordersObserver];
    [_ordersObserver release];
    _ordersObserver = nil;
    
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)update
{
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/orders" withAction:_order.orderId callback:^(NSDictionary *response) {
        if (response[@"order"]) {
            self.order = [[[FasTOrder alloc] initWithInfo:response[@"order"]] autorelease];
            [self reload];
            [self.tableView reloadData];
        }
        
        [_refresh endRefreshing];
    }];
}

- (void)reload
{
    UIColor *color = _order.paid ? [UIColor greenColor] : [UIColor redColor];
    NSAttributedString *paid = [[[NSAttributedString alloc] initWithString:(_order.paid ? @"ja" : @"nein") attributes:@{ NSForegroundColorAttributeName: color, NSFontAttributeName: [UIFont boldSystemFontOfSize:18] }] autorelease];
    
    [_infoTableRows release];
    _infoTableRows = [NSMutableArray arrayWithArray:@[
        @[@"Nummer", _order.number],
        @[@"Besteller", [_order fullNameWithLastNameFirst:YES]],
        @[@"Gesamtbetrag", [_order localizedTotal]],
        @[@"aufgegeben", [_dateFormatter stringFromDate:_order.created]],
        @[@"bezahlt", paid],
        @[@"Saldo", [_order localizedBalance]]
    ]];
    [_infoTableRows retain];
    
    self.refundBarButton.enabled = _order.balance != 0;
}

- (IBAction)selectAllTickets:(id)sender
{
    NSIndexPath *indexPath;
    for (NSInteger i = 0, count = _order.tickets.count; i < count; i++) {
        FasTTicket *ticket = _order.tickets[i];
        if (!ticket.cancelled) {
            indexPath = [NSIndexPath indexPathForRow:i inSection:1];
            if (_selectAllTicketsToggle) {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            } else {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
    
    [self updateAfterTicketSelection];
}

- (IBAction)showTicketActionSheet:(id)sender {
    NSMutableArray *tickets = [NSMutableArray array];
    for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
        [tickets addObject:_order.tickets[path.row]];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.barButtonItem = _ticketsPopoverBarButton;
    UIAlertAction *action;
    
    BOOL pay = !_order.paid;
    BOOL cancelOrResale = YES;
    for (FasTTicket *ticket in tickets) {
        if (ticket.pickedUp || ticket.cancelled || ticket.resale) {
            pay = NO;
        }
        if (ticket.cancelled || ticket.resale) {
            cancelOrResale = NO;
        }
    }
    
    // pay
    if (pay) {
        action = [UIAlertAction actionWithTitle:@"bezahlen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTPurchaseControllerAddTicketsToPay" object:nil userInfo:@{ @"tickets": tickets }];
        }];
        [alert addAction:action];
    }
    
    // print
    action = [UIAlertAction actionWithTitle:@"drucken" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[FasTTicketPrinter sharedPrinter] printTickets:tickets];
        [[FasTApi defaultApi] pickUpTickets:tickets];
    }];
    [alert addAction:action];
    
    if (cancelOrResale) {
        // resale
        action = [UIAlertAction actionWithTitle:@"zum Weiterverkauf freigeben" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSString *message = [NSString stringWithFormat:@"Möchten Sie %tu Tickets wirklich zum Weiterverkauf freigeben?", tickets.count];
            [self showAlertForTicketActionWithTitle:@"Tickets zum Weiterverkauf freigeben" message:message actionTitle:@"freigeben" handler:^{
                [self performApiAction:@selector(enableResaleForTickets:callback:) onTickets:tickets];
            }];
        }];
        [alert addAction:action];

        // cancellation
        action = [UIAlertAction actionWithTitle:@"stornieren" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSString *message = [NSString stringWithFormat:@"Möchten Sie %tu Tickets wirklich stornieren?", tickets.count];
            [self showAlertForTicketActionWithTitle:@"Tickets stornieren" message:message actionTitle:@"stornieren" handler:^{
                [self performApiAction:@selector(cancelTickets:callback:) onTickets:tickets];
            }];
        }];
        [alert addAction:action];
    }
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)showAlertForTicketActionWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(void))handler {
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmationAction;
    confirmationAction = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (handler) {
            handler();
        }
    }];
    [confirmation addAction:confirmationAction];
    
    confirmationAction = [UIAlertAction actionWithTitle:@"abbrechen" style:UIAlertActionStyleCancel handler:NULL];
    [confirmation addAction:confirmationAction];
    
    [self presentViewController:confirmation animated:YES completion:NULL];
}

- (void)performApiAction:(SEL)apiSelector onTickets:(NSArray *)tickets {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    hud.label.text = NSLocalizedStringByKey(@"pleaseWait");
    
    [[FasTApi defaultApi] performSelector:apiSelector withObject:tickets withObject:^(FasTOrder *order) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTUpdatedOrderInfo" object:nil userInfo:@{ @"order": order }];
        [hud hideAnimated:YES];
    }];
}

- (IBAction)openInSafari
{
    NSString *url = [[FasTApi defaultApi] URLForOrder:_order];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (IBAction)payBalance
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTPurchaseControllerAddOrderPayment" object:nil userInfo:@{ @"amount": @(-_order.balance), @"order": _order }];
}

- (void)updateAfterTicketSelection
{
    _selectAllTicketsToggle = !_selectAllTicketsToggle;
    _ticketsPopoverBarButton.enabled = self.tableView.indexPathsForSelectedRows.count > 0;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Allgemein";
            break;
        case 1:
            return [NSString stringWithFormat:@"%li Tickets", (long)_order.numberOfTickets];
            break;
        default:
            return @"Protokoll";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return _infoTableRows.count;
            break;
        case 1:
            return _order.tickets.count;
            break;
        default:
            return _order.logEvents.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return 73;
    } else {
        return 44;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case 0: {
            NSArray *row = _infoTableRows[indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:row.count > 2 ? row[2] : @"FasTOrderDetailsInfoCell"];
            for (int i = 0; i < 2; i++) {
                UILabel *label = (UILabel *)[cell viewWithTag:i+1];
                if ([row[i] isKindOfClass:[NSAttributedString class]]) {
                    [label setAttributedText:row[i]];
                } else {
                    [label setText:row[i]];
                }
            }
            break;
        }
            
        case 1: {
            FasTTicket *ticket = _order.tickets[indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:ticket.cancelled ? @"FasTOrderDetailsCancelledTicketCell" : @"FasTOrderDetailsTicketCell"];
            for (int i = 1; i <= 6; i++) {
                UILabel *label = (UILabel *)[cell viewWithTag:i];
                switch (i) {
                    case 1:
                        label.text = [NSString stringWithFormat:label.text, ticket.number];
                        break;
                    case 2:
                        label.text = [NSString stringWithFormat:label.text, ticket.date.localizedString];
                        break;
                    case 3:
                        label.text = [NSString stringWithFormat:label.text, ticket.type.name, ticket.type.localizedPrice];
                        break;
                    case 4:
                        if (ticket.cancelled) {
                            label.text = [NSString stringWithFormat:label.text, ticket.cancelReason];
                        }
                        break;
                    case 5:
                        if (!ticket.cancelled) {
                            if (ticket.resale) {
                                NSMutableAttributedString *text = [[[NSMutableAttributedString alloc] initWithString:@"Weiterverkauf "] autorelease], *resold;
                                if (ticket.seat.taken) {
                                    resold = [[[NSMutableAttributedString alloc] initWithString:@"erfolgreich"] autorelease];
                                    [resold addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:NSMakeRange(0, 11)];
                                } else {
                                    resold = [[[NSMutableAttributedString alloc] initWithString:@"möglich"] autorelease];
                                    [resold addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(0, 7)];
                                }
                                [text appendAttributedString:resold];
                                label.attributedText = text;
                            
                            } else {
                                NSMutableAttributedString *text = [[[NSMutableAttributedString alloc] initWithString:@"Abgeholt: "] autorelease], *pickedUp;
                                if (ticket.pickedUp) {
                                    pickedUp = [[[NSMutableAttributedString alloc] initWithString:@"ja"] autorelease];
                                } else {
                                    pickedUp = [[[NSMutableAttributedString alloc] initWithString:@"nein"] autorelease];
                                    [pickedUp addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 4)];
                                }
                                [text appendAttributedString:pickedUp];
                                label.attributedText = text;
                            }
                        }
                        break;
                    case 6:
                        label.hidden = !ticket.date.event.isBoundToSeats;
                        if (!label.hidden) {
                            label.text = [NSString stringWithFormat:label.text, ticket.seat.fullNumber];
                        }
                }
            }
            if ([_highlightedTicketId isKindOfClass:[NSString class]] && [_highlightedTicketId isEqualToString:ticket.ticketId]) {
                cell.backgroundColor = [UIColor yellowColor];
            }
            break;
        }
        
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"FasTOrderDetailsLogEventCell"];
            FasTLogEvent *event = _order.logEvents[indexPath.row];
            
            [(UILabel *)[cell viewWithTag:1] setText:[_dateFormatter stringFromDate:event.date]];
            [(UILabel *)[cell viewWithTag:2] setText:event.message];
        }
    }
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) [self updateAfterTicketSelection];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) [self updateAfterTicketSelection];
}

@end
