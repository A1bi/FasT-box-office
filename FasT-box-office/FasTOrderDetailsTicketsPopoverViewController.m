//
//  FasTOrderDetailsTicketsPopoverViewControllerTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsTicketsPopoverViewController.h"
#import "FasTTicket.h"
#import "FasTOrder.h"
#import "FasTTicketPrinter.h"
#import "FasTApi.h"
#import "MBProgressHUD.h"

@interface FasTOrderDetailsTicketsPopoverViewController ()

- (void)dismiss;

@end

@implementation FasTOrderDetailsTicketsPopoverViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _rows = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc
{
    [_rows release];
    [super dealloc];
}

- (void)setTickets:(NSArray *)tickets
{
    if (_tickets != tickets) {
        [_tickets release];
        _tickets = [tickets retain];
    }
    FasTOrder *order = ((FasTTicket *)_tickets.firstObject).order;
    
    BOOL pay = !order.paid;
    if (pay) {
        for (FasTTicket *ticket in tickets) {
            if (ticket.pickedUp) {
                pay = NO;
                break;
            }
        }
    }
    
    [_rows removeAllObjects];
    if (pay) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverPayCell"];
    }
    [_rows addObject:@"FasTOrderDetailsTicketsPopoverCancelCell"];
    [_rows addObject:@"FasTOrderDetailsTicketsPopoverPrintCell"];
//    if (_rows.count == 0) {
//        [_rows addObject:@"FasTOrderDetailsTicketsPopoverNoneCell"];
//    }
}

#pragma mark table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_rows[indexPath.row]];
    return cell;
}

#pragma mark table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [tableView cellForRowAtIndexPath:indexPath].reuseIdentifier;
    if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverPayCell"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTPurchaseControllerAddTicketsToPay" object:nil userInfo:@{ @"tickets": _tickets }];
        [self dismiss];
    
    } else if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverPrintCell"]) {
        [[FasTTicketPrinter sharedPrinter] printTickets:_tickets];
        [[FasTApi defaultApi] pickUpTickets:_tickets];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tickets werden gedruckt" message:@"Die ausgewählten Tickets werden nun gedruckt. Einen Moment bitte..." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Alles klar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self dismiss];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:NULL];
        
    } else if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverCancelCell"]) {
        NSString *message = [NSString stringWithFormat:@"Möchten Sie %i Tickets wirklich stornieren?", _tickets.count];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Tickets stornieren" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"stornieren" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [hud setMode:MBProgressHUDModeIndeterminate];
            [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
            [[FasTApi defaultApi] cancelTickets:_tickets callback:^(FasTOrder *order) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTUpdatedOrderInfo" object:nil userInfo:@{ @"order": order }];
                [hud hide:YES];
            }];
            
            [self dismiss];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"abbrechen" style:UIAlertActionStyleCancel handler:NULL];
        [alert addAction:action];
        [alert addAction:cancelAction];
        
        [self presentViewController:alert animated:YES completion:NULL];
    }
}

- (void)dismiss
{
    if ([_popover.delegate popoverControllerShouldDismissPopover:_popover]) {
        [_popover dismissPopoverAnimated:YES];
    }
}

@end
