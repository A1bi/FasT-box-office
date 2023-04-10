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

@end

@implementation FasTTodaysOrdersViewController

- (void)updateOrders
{
    [self fetchOrders:@{ @"unpaid": @(1), @"event_today": @(1) } callback:NULL];
}

@end
