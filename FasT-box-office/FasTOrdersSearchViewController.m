//
//  FasTOrdersTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrdersSearchViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTOrderDetailsViewController.h"
@import MBProgressHUD;

@interface FasTOrdersSearchViewController ()
{
    NSDate *ordersStartDate;
}

@end

@implementation FasTOrdersSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    orders = [[NSMutableArray alloc] init];
    
    // orders can be at most 200 days old
    ordersStartDate = [[NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * 200] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
}

- (void)dealloc
{
    [_tableView release];
    [orders release];
    [highlightedTicketId release];
    [ordersStartDate release];
    [_searchFields release];
    [super dealloc];
}

- (void)didEnterSearchTerm:(UITextField *)sender
{
    NSString *searchTerm = sender.text;
    if ([searchTerm length] < 1) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    hud.label.text = NSLocalizedStringByKey(@"pleaseWait");
    
    [[FasTApi defaultApi] getResource:@"api/box_office" withAction:@"search" data:@{ @"q": searchTerm } callback:^(NSDictionary *response) {
        [hud hideAnimated:YES];
        
        if (!response[@"error"]) {
            [orders removeAllObjects];
            
            for (NSDictionary *orderInfo in response[@"orders"]) {
                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo event:[[FasTApi defaultApi] event]] autorelease];
                if ([order.created laterDate:ordersStartDate] == order.created) {
                    [orders addObject:order];
                }
            }
            
            if (orders.count == 1) {
                highlightedTicketId = response[@"ticket_id"];
                [self performSegueWithIdentifier:@"FasTOrdersSearchDirectDetailsSegue" sender:self];
            }
            
            [self.tableView reloadData];
        }
    }];
}

- (void)clearFormAndResults
{
    for (UITextField *field in _searchFields) {
        field.text = nil;
    }
    [orders removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [orders count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [orders count] ? @"Suchergebnisse" : @"Keine Bestellungen gefunden";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FasTOrder *order = orders[[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(order.cancelled) ? @"FasTOrdersCancelledTableCell" : @"FasTOrdersTableCell"];
    [(UILabel *)[cell viewWithTag:1] setText:[NSString stringWithFormat:@"#%@", [order number]]];
    [(UILabel *)[cell viewWithTag:2] setText:[order fullNameWithLastNameFirst:YES]];
    [(UILabel *)[cell viewWithTag:3] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"numberOfTickets"), [order numberOfTickets]]];
    [(UILabel *)[cell viewWithTag:4] setText:[order localizedTotal]];
    
    return cell;
}

#pragma mark storyboard delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FasTOrderDetailsViewController *details = [segue destinationViewController];
    if ([segue.identifier isEqualToString:@"FasTOrdersSearchDirectDetailsSegue"]) {
        details.order = [orders firstObject];
        details.highlightedTicketId = highlightedTicketId;
    } else {
        NSIndexPath *path = [_tableView indexPathForCell:sender];
        details.order = orders[path.row];
    }
}

@end
