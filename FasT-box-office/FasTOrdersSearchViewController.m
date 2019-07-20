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

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // orders can be at most 200 days old
        ordersStartDate = [[NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * 200] retain];
    }
    return self;
}

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
    [ordersStartDate release];
    [super dealloc];
}

- (void)didEnterSearchTerm:(UITextField *)sender
{
    NSString *searchTerm = sender.text;
    if ([searchTerm length] < 1) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    hud.label.text = NSLocalizedStringByKey(@"pleaseWait");
    
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/orders" withAction:nil data:@{ @"q": searchTerm } callback:^(NSDictionary *response) {
        [hud hideAnimated:YES];
        
        if (!response[@"error"]) {
            [orders removeAllObjects];
            
            for (NSDictionary *orderInfo in response[@"orders"]) {
                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo] autorelease];
                if ([order.created laterDate:ordersStartDate] == order.created) {
                    [orders addObject:order];
                }
            }
            
            if (orders.count == 1) {
                highlightedTicketId = [response[@"ticket_id"] retain];
                [self performSegueWithIdentifier:@"FasTOrdersSearchDirectDetailsSegue" sender:self];
            }
            
            [self.tableView reloadData];
        }
    }];
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
