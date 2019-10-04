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
#import "FasTEventDate.h"

#define NUM_AVAILABILITIES 3

@interface FasTOrderTicketTypesViewController ()

- (NSArray *)ticketTypesWithAvailability:(FasTTicketTypeAvailability)availability;
- (NSArray *)ticketTypesForSection:(NSInteger)section;
- (FasTTicketTypeAvailability)availabilityForSection:(NSInteger)section;

@end

@implementation FasTOrderTicketTypesViewController

- (NSArray *)ticketTypesWithAvailability:(FasTTicketTypeAvailability)availability
{
    FasTOrderViewController *vc = (FasTOrderViewController *)self.navigationController;
    NSArray *ticketTypes = vc.event.ticketTypes;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"availability = %d", availability];
    return [ticketTypes filteredArrayUsingPredicate:predicate];
}

- (NSArray *)ticketTypesForSection:(NSInteger)section
{
    FasTTicketTypeAvailability availability = [self availabilityForSection:section];
    return [self ticketTypesWithAvailability:availability];
}

- (FasTTicketTypeAvailability)availabilityForSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return FasTTicketTypeAvailabilityBoxOffice;
        case 2:
            return FasTTicketTypeAvailabilityExclusive;
        default:
            return FasTTicketTypeAvailabilityUniversal;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_AVAILABILITIES + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section < NUM_AVAILABILITIES) ? [self ticketTypesForSection:section].count : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section >= NUM_AVAILABILITIES || [self ticketTypesForSection:section].count < 1) return nil;

    FasTTicketTypeAvailability availability = [self availabilityForSection:section];
    switch (availability) {
        case FasTTicketTypeAvailabilityUniversal:
            return @"Öffentlich erhältliche Kategorien";
        case FasTTicketTypeAvailabilityExclusive:
            return @"Exklusive Kategorien";
        case FasTTicketTypeAvailabilityBoxOffice:
            return @"Kategorien für die Abendkasse";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section < NUM_AVAILABILITIES) {
        FasTTicketType *type = [self ticketTypesForSection:indexPath.section][indexPath.row];

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
    if (indexPath.section < NUM_AVAILABILITIES) {
        return 81;
    } else {
        return 60;
    }
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSMutableArray *tickets = [NSMutableArray array];

    for (NSInteger section = 0; section < NUM_AVAILABILITIES; section++) {
        NSArray *ticketTypes = [self ticketTypesForSection:section];

        for (NSInteger row = 0; row < ticketTypes.count; row++) {
            FasTTicketType *ticketType = ticketTypes[row];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            FasTOrderTicketTypesCell *cell = (FasTOrderTicketTypesCell *)[self.tableView cellForRowAtIndexPath:indexPath];

            for (NSInteger i = 0; i < cell.stepper.value; i++) {
                FasTTicket *ticket = [[[FasTTicket alloc] init] autorelease];
                ticket.type = ticketType;
                [tickets addObject:ticket];
            }
        }
    }
    
    if (tickets.count > 0) {
        FasTOrder *order = ((FasTOrderViewController *)self.navigationController).order;
        order.tickets = tickets;
        
        if (!order.date.event.hasSeatingPlan) {
            [((FasTOrderViewController *)self.navigationController).delegate didPlaceOrder:order];
        } else {
            return YES;
        }
    }
    
    return NO;
}

@end
