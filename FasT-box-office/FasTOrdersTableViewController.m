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
#import "FasTOrderDetailsViewController.h"
#import "MBProgressHUD.h"

@interface FasTOrdersTableViewController ()

- (void)resetDisplayedOrders;

@end

@implementation FasTOrdersTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setTitle:NSLocalizedStringByKey(@"ordersControllerTabTitle")];
        [[self navigationItem] setTitle:NSLocalizedStringByKey(@"ordersControllerNavigationTitle")];
        
        UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)] autorelease];
        [searchBar setKeyboardType:UIKeyboardTypeDecimalPad];
        [searchBar setPlaceholder:NSLocalizedStringByKey(@"ordersSearchPlaceholder")];
        [[self tableView] setTableHeaderView:searchBar];
        
        searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        [searchDisplay setDelegate:self];
        [searchDisplay setSearchResultsDataSource:self];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!orders || !lastUpdate || [lastUpdate timeIntervalSinceNow] > 300) {
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
                [self resetDisplayedOrders];
                
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
    [foundOrders release];
    [lastUpdate release];
    [super dealloc];
}

- (void)resetDisplayedOrders
{
    displayedOrders = orders;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [displayedOrders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"orderCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];   
    }
    
    FasTOrder *order = displayedOrders[[indexPath row]];
    [[cell textLabel] setText:[order fullNameWithLastNameFirst:YES]];
    [[cell detailTextLabel] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"numberOfTickets"), [order numberOfTickets]]];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FasTOrderDetailsViewController *details = [[[FasTOrderDetailsViewController alloc] initWithOrderNumber:[orders[[indexPath row]] number]] autorelease];
    [[self navigationController] pushViewController:details animated:YES];
}

#pragma mark search display delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName beginswith[c] $search || lastName beginswith[c] $search || number beginswith $search"];
    predicate = [predicate predicateWithSubstitutionVariables:@{@"search": searchString}];
    [foundOrders release];
    displayedOrders = foundOrders = [[orders filteredArrayUsingPredicate:predicate] retain];
    return YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self resetDisplayedOrders];
}

@end
