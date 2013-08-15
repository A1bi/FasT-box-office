//
//  FasTOrdersTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrdersTableViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "MBProgressHUD.h"

static NSString *cellId = @"orderCell";

@interface FasTOrdersTableViewController ()

@end

@implementation FasTOrdersTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setTitle:NSLocalizedStringByKey(@"ordersControllerTabTitle")];
        [[self navigationItem] setTitle:NSLocalizedStringByKey(@"ordersControllerNavigationTitle")];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!orders || !lastUpdate || [lastUpdate timeIntervalSinceNow] > 300) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [hud setMode:MBProgressHUDModeIndeterminate];
        [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
        
        [[FasTApi defaultApi] getOrdersForCurrentDateWithCallback:^(NSArray *o) {
            [hud hide:YES];
            
            if (o) {
                [orders release];
                orders = [o retain];
                
                [lastUpdate release];
                lastUpdate = [[NSDate date] retain];
                
                [[self tableView] reloadData];
            }
        }];
    }
}

- (void)dealloc
{
    [orders release];
    [lastUpdate release];
    [super dealloc];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];   
    }
    
    FasTOrder *order = orders[[indexPath row]];
    [[cell textLabel] setText:[order fullNameWithLastNameFirst:YES]];
    [[cell detailTextLabel] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"numberOfTickets"), [order numberOfTickets]]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
