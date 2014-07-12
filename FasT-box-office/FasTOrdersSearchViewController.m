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

- (void)reload;

@end

@implementation FasTOrdersSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [super dealloc];
}

- (void)reload
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
    
    [[FasTApi defaultApi] getOrdersForCurrentDateWithCallback:^(NSArray *o) {
        [hud hide:YES];
        
        if (o) {
            NSMutableArray *tmpOrders = [NSMutableArray array];
            for (FasTOrder *order in o) {
                NSInteger empty = 0;
                NSArray *requiredKeys = @[@"lastName", @"firstName"];
                for (NSString *key in requiredKeys) {
                    id value = [order performSelector:NSSelectorFromString(key)];
                    if (![value isKindOfClass:[NSString class]] || [value length] <= 0) {
                        empty++;
                    }
                }
                if (empty < [requiredKeys count]) [tmpOrders addObject:order];
            }
            
            [orders release];
            orders = [[NSMutableArray arrayWithArray:tmpOrders] retain];
            
            //[[self tableView] reloadData];
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
    //return orders ? [orders count] : 0;
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Suchergebnisse";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FasTOrdersTableCell"];
    NSArray *labelTexts = @[@"Max Mustermann", @"4 Tickets", @"48,00 €"];
    int i = 0;
    for (NSString *text in labelTexts) {
        [(UILabel *)[cell viewWithTag:i+1] setText:text];
        i++;
    }
    
//    FasTOrder *order = orders[[indexPath row]];
//    [[cell textLabel] setText:[order fullNameWithLastNameFirst:YES]];
//    [[cell detailTextLabel] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"numberOfTickets"), [order numberOfTickets]]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    FasTOrderDetailsViewController *details = [[[FasTOrderDetailsViewController alloc] initWithOrderNumber:[orders[[indexPath row]] number]] autorelease];
//    [[self navigationController] pushViewController:details animated:YES];
}

#pragma mark storyboard delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //FasTOrderDetailsViewController *details = [segue destinationViewController];
}

@end
