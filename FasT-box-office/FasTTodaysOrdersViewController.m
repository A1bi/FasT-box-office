//
//  FasTTodaysOrdersViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 27.07.18.
//  Copyright © 2018 Albisigns. All rights reserved.
//

#import "FasTTodaysOrdersViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"

@interface FasTTodaysOrdersViewController ()
{
    UIRefreshControl *refresh;
}

- (void)updateOrders;

@end

@implementation FasTTodaysOrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(updateOrders) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateOrders];
}

- (void)dealloc
{
    [refresh release];
    [super dealloc];
}

- (void)updateOrders
{
    [refresh beginRefreshing];
    [self retain];
    
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/orders" withAction:nil data:@{ @"unpaid": @(1), @"event_today": @(1) } callback:^(NSDictionary *response) {
        if (!response[@"error"]) {
            [orders removeAllObjects];
            
            for (NSDictionary *orderInfo in response[@"orders"]) {
                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo] autorelease];
                [orders addObject:order];
            }
            
            [self.tableView reloadData];
        }
        
        [refresh endRefreshing];
        [self release];
    }];
}

@end
