//
//  FasTOrdersTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrdersListViewController.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTOrderDetailsViewController.h"
@import MBProgressHUD;

@implementation FasTOrdersListViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        orders = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(updateOrders) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refresh];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOrders) name:@"FasTPurchaseFinished" object:nil];
    
    [self updateOrders];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [refresh release];
    [_tableView release];
    [orders release];
    [super dealloc];
}

- (void)updateOrders
{
}

- (void)fetchOrders:(NSDictionary *)params callback:(void (^)(NSDictionary *))callback
{
    [refresh beginRefreshing];
    [self retain];
    
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/orders" withAction:nil data:params callback:^(NSDictionary *response) {
        [orders removeAllObjects];
        
        for (NSDictionary *orderInfo in response[@"orders"]) {
            FasTOrder *order = [[[FasTOrder alloc] initWithInfo:orderInfo] autorelease];
            [orders addObject:order];
        }
        
        if (callback) callback(response);
            
        [self.tableView reloadData];
        [refresh endRefreshing];
        [self release];
    }];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [orders count] ? @"Suchergebnisse" : @"Keine Bestellungen gefunden";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FasTOrder *order = orders[[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(order.cancelled) ? @"FasTOrdersCancelledTableCell" : @"FasTOrdersTableCell"];
    [(UILabel *)[cell viewWithTag:1] setText:[NSString stringWithFormat:@"#%@", [order number]]];
    [(UILabel *)[cell viewWithTag:2] setText:[order fullNameWithLastNameFirst:YES]];
    [(UILabel *)[cell viewWithTag:3] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"numberOfTickets"), [order numberOfTickets]]];
    [(UILabel *)[cell viewWithTag:4] setText:[order localizedTotal]];
    
    return cell;
}

#pragma mark storyboard delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    FasTOrderDetailsViewController *details = [segue destinationViewController];
    NSIndexPath *path = [_tableView indexPathForCell:sender];
    details.order = orders[path.row];
}

@end
