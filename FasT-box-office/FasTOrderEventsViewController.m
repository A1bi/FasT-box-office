//
//  FasTOrderEventsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import "FasTOrderEventsViewController.h"
#import "FasTOrderViewController.h"
#import "FasTApi.h"
#import "FasTEvent.h"

@interface FasTOrderEventsViewController ()

- (NSArray *)events;

@end

@implementation FasTOrderEventsViewController

- (NSArray *)events
{
    return [FasTApi defaultApi].events.allValues;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self events].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventRow" forIndexPath:indexPath];
    
    FasTEvent *event = [self events][indexPath.row];
    cell.textLabel.text = event.name;
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *path = [self.tableView indexPathForCell:sender];
    
    FasTOrderViewController *vc = (FasTOrderViewController *)self.navigationController;
    vc.event = (FasTEvent *)[self events][path.row];
}

@end
