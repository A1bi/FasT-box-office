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
#import "FasTFormatter.h"
#import "FasTSeat.h"

@interface FasTTicketsViewController ()

- (void)updatePrintBtn;
- (void)print;

@end

@implementation FasTTicketsViewController

- (id)initWithTickets:(NSArray *)t
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        tickets = [t retain];
        
        printBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringByKey(@"printTickets") style:UIBarButtonItemStyleBordered target:self action:@selector(print)];
        [[self tableView] setAllowsMultipleSelection:YES];
        [self setTitle:NSLocalizedStringByKey(@"ticketOverview")];
    }
    return self;
}

- (void)dealloc
{
    [tickets release];
    [printBtn release];
    [super dealloc];
}

- (void)updatePrintBtn
{
    [printBtn setEnabled:YES];
    [[self navigationItem] setRightBarButtonItem:!![[[self tableView] indexPathsForSelectedRows] count] ? printBtn : nil];
}

- (void)print
{
    [printBtn setEnabled:NO];
    NSMutableArray *ticketsToPrint = [NSMutableArray array];
    for (NSIndexPath *path in [[self tableView] indexPathsForSelectedRows]) {
        [ticketsToPrint addObject:tickets[[path row]]];
    }
    [[FasTTicketPrinter sharedPrinter] printTickets:ticketsToPrint];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId] autorelease];
    }
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@: %@", [ticket number], [[ticket type] name]]];
    [[cell detailTextLabel] setText:[ticket canCheckIn] ? [NSString stringWithFormat:NSLocalizedStringByKey(@"ticketsControllerCellDescription"), [FasTFormatter stringForEventDate:[[ticket date] date]], [[ticket seat] blockName], [[ticket seat] number]] : NSLocalizedStringByKey(@"ticketsControllerCellInvalid")];
    
    return cell;
}

#pragma mark table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updatePrintBtn];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updatePrintBtn];
}

@end
