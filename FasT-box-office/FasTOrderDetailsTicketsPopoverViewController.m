//
//  FasTOrderDetailsTicketsPopoverViewControllerTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsTicketsPopoverViewController.h"
#import "FasTTicket.h"
#import "FasTTicketPrinter.h"
#import "FasTApi.h"

@interface FasTOrderDetailsTicketsPopoverViewController ()

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
    
    [_rows removeAllObjects];
    BOOL pay = YES, print = YES;
    for (FasTTicket *ticket in tickets) {
        if (ticket.paid) {
            if (pay) pay = NO;
        } else {
            if (print) print = NO;
        }
    }
    
    if (pay) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverPayCell"];
    }
    if (print) {
        [_rows addObject:@"FasTOrderDetailsTicketsPopoverPrintCell"];
    }
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
    
    } else if ([identifier isEqualToString:@"FasTOrderDetailsTicketsPopoverPrintCell"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tickets werden gedruckt" message:@"Die ausgewählten Tickets werden nun gedruckt. Einen Moment bitte..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
        [[FasTTicketPrinter sharedPrinter] printTickets:_tickets];
        
        [[FasTApi defaultApi] markTickets:_tickets paid:NO pickedUp:YES];
    }
    
    if ([_popover.delegate popoverControllerShouldDismissPopover:_popover]) {
        [_popover dismissPopoverAnimated:YES];
    }
}

@end
