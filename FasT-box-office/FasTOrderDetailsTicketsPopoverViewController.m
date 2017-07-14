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
@import MBProgressHUD;

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
    [_popover release];
    [_tickets release];
    [super dealloc];
}

- (void)setTickets:(NSArray *)tickets
{
    if (_tickets != tickets) {
        [_tickets release];
        _tickets = [tickets retain];
    }
    FasTOrder *order = ((FasTTicket *)_tickets.firstObject).order;
    
    BOOL pay = order.balance < 0;
    BOOL cancel = YES;
    BOOL resale = YES;
    for (FasTTicket *ticket in tickets) {
        if (ticket.pickedUp || ticket.cancelled) {
            pay = NO;
        }
        if (ticket.cancelled) {
            cancel = NO;
        } else if (ticket.resale) {
            resale = NO;
        }
    }
    
    [_rows removeAllObjects];
    
    if (pay) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverPayCell"];
    }
    if (cancel) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverCancelCell"];
        if (resale) {
            [_rows addObject:@"FasTOrderDetailsTicketsPopoverResaleCell"];
        }
    }
    [_rows addObject:@"FasTOrderDetailsTicketsPopoverPrintCell"];
    
    if (_rows.count == 0) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverNoneCell"];
    }
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
        
    } else if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverCancelCell"] || [identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverResaleCell"]) {
        
        NSString *alertTitle, *alertMessage, *actionTitle;
        SEL apiSelector;
        if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverCancelCell"]) {
            alertMessage = [NSString stringWithFormat:@"Möchten Sie %tu Tickets wirklich stornieren?", _tickets.count];
            alertTitle = @"Tickets stornieren";
            actionTitle = @"stornieren";
            apiSelector = @selector(cancelTickets:callback:);
            
        } else {
            alertMessage = [NSString stringWithFormat:@"Möchten Sie %tu Tickets wirklich zum Weiterverkauf freigeben?", _tickets.count];
            alertTitle = @"Tickets zum Weiterverkauf freigeben";
            actionTitle = @"freigeben";
            apiSelector = @selector(enableResaleForTickets:callback:);
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [hud setMode:MBProgressHUDModeIndeterminate];
            hud.label.text = NSLocalizedStringByKey(@"pleaseWait");
            [[FasTApi defaultApi] performSelector:apiSelector withObject:_tickets withObject:^(FasTOrder *order) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTUpdatedOrderInfo" object:nil userInfo:@{ @"order": order }];
                [hud hideAnimated:YES];
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
