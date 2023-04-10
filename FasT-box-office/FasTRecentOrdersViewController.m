//
//  FasTTodaysOrdersViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 27.07.18.
//  Copyright © 2018 Albisigns. All rights reserved.
//

#import "FasTRecentOrdersViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"

@interface FasTRecentOrdersViewController ()
{
    NSDateFormatter *dateFormatter;
}

@end

@implementation FasTRecentOrdersViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
}

- (void)dealloc
{
    [dateFormatter release];
    [super dealloc];
}

- (void)updateOrders
{
    [self fetchOrders:@{ @"recent": @(1) } callback:NULL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    FasTOrder *order = orders[[indexPath row]];
    [(UILabel *)[cell viewWithTag:2] setText:[dateFormatter stringFromDate:order.createdAt]];
    
    return cell;
}

@end
