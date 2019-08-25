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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrders) name:@"FasTPurchaseFinished" object:nil];
    
    [self updateOrders];
}

- (void)dealloc
{
    [refresh release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)updateOrders
{
    [refresh beginRefreshing];
    [self retain];
    
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/orders" withAction:nil data:@{ @"unpaid": @(1), @"event_today": @(1) } callback:^(NSDictionary *response) {
        [orders removeAllObjects];
        
        for (NSDictionary *orderInfo in response[@"orders"]) {
            FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo] autorelease];
            [orders addObject:order];
        }
        
        [self.tableView reloadData];
        
        [refresh endRefreshing];
        [self release];
    }];
}

@end
