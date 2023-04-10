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

@implementation FasTOrdersSearchViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (orders.count < 1) {
        [_searchField becomeFirstResponder];
    }
}

- (void)dealloc
{
    [_searchField release];
    [highlightedTicketId release];
    [super dealloc];
}

- (void)updateOrders
{
    if (!searchTerm) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    hud.label.text = NSLocalizedStringByKey(@"pleaseWait");
    
    [self fetchOrders:@{ @"q": searchTerm } callback:^(NSDictionary *response) {
        [hud hideAnimated:YES];
        
        if (orders.count == 1) {
            highlightedTicketId = [response[@"ticket_id"] retain];
            [self performSegueWithIdentifier:@"FasTOrdersSearchDirectDetailsSegue" sender:self];
        }
    }];
}

- (void)didEnterSearchTerm:(UITextField *)sender
{
    [searchTerm release];
    searchTerm = [sender.text retain];
    if ([searchTerm length] < 1) return;

    [self updateOrders];
}

- (void)clearFormAndResults
{
    _searchField.text = nil;
    [orders removeAllObjects];
    [self.tableView reloadData];
}

#pragma mark storyboard delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FasTOrderDetailsViewController *details = [segue destinationViewController];
    if ([segue.identifier isEqualToString:@"FasTOrdersSearchDirectDetailsSegue"]) {
        details.order = [orders firstObject];
        details.highlightedTicketId = highlightedTicketId;
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

@end
