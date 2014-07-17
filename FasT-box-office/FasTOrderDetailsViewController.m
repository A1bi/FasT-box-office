//
//  FasTOrderDetailsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsViewController.h"
#import "FasTOrderDetailsTicketsPopoverViewController.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTSeat.h"
#import "FasTEventDate.h"
#import "FasTApi.h"
#import "FasTFormatter.h"
#import "FasTTicketPrinter.h"
#import "MBProgressHUD.h"

@interface FasTOrderDetailsViewController ()

- (void)printTickets;
- (void)reload;
- (void)updateAfterTicketSelection;

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
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_order) {
        [self reload];
        self.navigationItem.title = [NSString stringWithFormat:self.navigationItem.title, _order.number];
    }
    
    [self.tableView setEditing:YES animated:NO];
    [self.navigationController setToolbarHidden:NO];
}

- (void)printTickets
{
    [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:_order];
    [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
}

- (void)reload
{
    NSMutableArray *rows = [NSMutableArray arrayWithArray:@[
                                                            @[@"Nummer", _order.number],
                                                            @[@"Besteller", [_order fullNameWithLastNameFirst:YES]],
                                                            @[@"Gesamtbetrag", [_order localizedTotal]],
                                                            @[@"aufgegeben", [_dateFormatter stringFromDate:_order.created]]
                                                            ]];
    if (_order.cancelled) {
        [rows addObject:@[@"Stornierung", _order.cancelReason, @"FasTOrderDetailsCancellationCell"]];
    }
    [_infoTableRows release];
    _infoTableRows = [[NSArray arrayWithArray:rows] retain];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverSegue"]) {
        FasTOrderDetailsTicketsPopoverViewController *popover = segue.destinationViewController;
        NSMutableArray *tickets = [NSMutableArray array];
        for (NSIndexPath *path in self.tableView.indexPathsForSelectedRows) {
            [tickets addObject:_order.tickets[path.row]];
        }
        popover.tickets = tickets;
    }
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
            return [NSString stringWithFormat:@"%d Tickets", _order.numberOfTickets];
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
                [(UILabel *)[cell viewWithTag:i+1] setText:row[i]];
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
                        } else {
                            label.text = [NSString stringWithFormat:label.text, ticket.paid ? @"ja" : @"nein"];
                        }
                        break;
                    case 5:
                        if (ticket.cancelled) {
                            
                        }
                        break;
                    case 6:
                        label.text = [NSString stringWithFormat:label.text, ticket.seat.blockName, ticket.seat.number];
                }
            }
            if (_highlightedTicketId && [_highlightedTicketId isEqualToString:ticket.ticketId]) {
                cell.backgroundColor = [UIColor yellowColor];
            }
            break;
        }
        
        default: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"FasTOrderDetailsLogEventCell"];
            NSArray *event = _order.logEvents[indexPath.row];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[event[0] integerValue]];
            
            [(UILabel *)[cell viewWithTag:1] setText:[_dateFormatter stringFromDate:date]];
            [(UILabel *)[cell viewWithTag:2] setText:event[1]];
        }
    }
    
    return cell;
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
