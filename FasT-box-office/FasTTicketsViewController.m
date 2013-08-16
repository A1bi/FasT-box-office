//
//  FasTTicketsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTTicketsViewController.h"
#import "FasTTicket.h"
#import "FasTTicketPrinter.h"

@interface FasTTicketsViewController ()

- (void)print;

@end

@implementation FasTTicketsViewController

- (id)initWithTickets:(NSArray *)t
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        tickets = [t retain];
        
        [self setTitle:NSLocalizedStringByKey(@"ticketOverview")];
        // TODO: fix
        UIBarButtonItem *btn = [[[UIBarButtonItem alloc] initWithTitle:@"drucken" style:UIBarButtonItemStyleBordered target:self action:@selector(print)] autorelease];
        [[self navigationItem] setRightBarButtonItem:btn];
    }
    return self;
}

- (void)dealloc
{
    [tickets release];
    [super dealloc];
}

- (void)print
{
    [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:[tickets[0] order]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tickets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FasTTicket *ticket = tickets[[indexPath row]];
    
    static NSString *cellId = @"ticketCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    }
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@: %@", [ticket number], [[ticket type] name]]];
    // TODO: fix
    [[cell detailTextLabel] setText:[ticket canCheckIn] ? @"gültig" : @"noch nicht oder nicht mehr gültig"];
    
    return cell;
}

@end
