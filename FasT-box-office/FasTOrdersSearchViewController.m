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
#import "MBProgressHUD.h"

@interface FasTOrdersSearchViewController ()

@end

@implementation FasTOrdersSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    orders = [[NSMutableArray alloc] init];
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
    [super dealloc];
}

- (void)didEnterSearchTerm:(UITextField *)sender
{
    NSString *searchTerm = sender.text;
    if ([searchTerm length] < 1) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
    
    [[FasTApi defaultApi] getResource:@"vorverkauf/bestellungen" withAction:@"suche" data:@{ @"q": searchTerm } callback:^(NSDictionary *response) {
        [hud hide:YES];
        
        if (!response[@"error"]) {
            [orders removeAllObjects];
            
            if (response[@"orders"]) {
                for (NSDictionary *orderInfo in response[@"orders"]) {
                    FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo event:[[FasTApi defaultApi] event]] autorelease];
                    [orders addObject:order];
                }
            
            } else if (response[@"order"]) {
                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:response[@"order"] event:[[FasTApi defaultApi] event]] autorelease];
                [orders addObject:order];
                if (response[@"ticket"]) {
                    highlightedTicketId = [response[@"ticket"] retain];
                }
                [self performSegueWithIdentifier:@"FasTOrdersSearchDirectDetailsSegue" sender:self];
            }
            
            [[self tableView] reloadData];
        }
    }];
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
