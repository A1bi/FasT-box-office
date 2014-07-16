//
//  FasTOrderDetailsTicketsPopoverViewControllerTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsTicketsPopoverViewController.h"
#import "FasTTicket.h"

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

@end
