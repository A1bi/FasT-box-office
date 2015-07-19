//
//  FasTOrderDatesViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTOrderDatesViewController.h"
#import "FasTOrderViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTFormatter.h"

@interface FasTOrderDatesViewController ()
{
    NSArray *_dates;
}

@end

@implementation FasTOrderDatesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"date >= %@", [NSDate date]];
    _dates = [[[FasTApi defaultApi].event.dates filteredArrayUsingPredicate:pred] retain];
}

- (void)dealloc
{
    [_dates release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dates.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dateRow" forIndexPath:indexPath];
    
    FasTEventDate *date = _dates[indexPath.row];
    cell.textLabel.text = [FasTFormatter stringForEventDate:date.date];
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *path = [self.tableView indexPathForCell:sender];
    
    FasTOrder *order = ((FasTOrderViewController *)self.navigationController).order;
    order.date = _dates[path.row];
}

@end
