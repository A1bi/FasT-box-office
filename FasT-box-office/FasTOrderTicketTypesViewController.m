//
//  FasTOrderTicketTypesViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTOrderTicketTypesViewController.h"
#import "FasTOrderTicketTypesCell.h"
#import "FasTOrderViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTTicketType.h"
#import "FasTTicket.h"
#import "FasTEvent.h"

@interface FasTOrderTicketTypesViewController ()
{
    NSArray *_ticketTypes;
}

@end

@implementation FasTOrderTicketTypesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _ticketTypes = [FasTApi defaultApi].event.ticketTypes;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _ticketTypes.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row < _ticketTypes.count) {
        FasTTicketType *type = _ticketTypes[indexPath.row];
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"ticketTypeRow" forIndexPath:indexPath];
        
        FasTOrderTicketTypesCell *c = (FasTOrderTicketTypesCell *)cell;
        c.nameLabel.text = type.name;
        c.priceLabel.text = type.localizedPrice;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"nextRow" forIndexPath:indexPath];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < _ticketTypes.count) {
        return 81;
    } else {
        return 60;
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSMutableArray *tickets = [NSMutableArray array];
    NSInteger i = 0;
    for (FasTTicketType *type in _ticketTypes) {
        FasTOrderTicketTypesCell *cell = (FasTOrderTicketTypesCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i++ inSection:0]];
        for (NSInteger j = 0; j < cell.stepper.value; j++) {
            
            FasTTicket *ticket = [[[FasTTicket alloc] init] autorelease];
            ticket.type = type;
            [tickets addObject:ticket];
            
        }
    }
    
    if (tickets.count > 0) {
        FasTOrder *order = ((FasTOrderViewController *)self.navigationController).order;
        order.tickets = tickets;
        
        if (![FasTApi defaultApi].event.isBoundToSeats) {
            [((FasTOrderViewController *)self.navigationController).delegate didPlaceOrder:order];
        } else {
            return YES;
        }
    }
    
    return NO;
}

@end
