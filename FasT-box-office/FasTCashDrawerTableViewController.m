//
//  FasTCashDrawerTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTCashDrawerTableViewController.h"
#import "FasTCashDrawer.h"

@interface FasTCashDrawerTableViewController ()

@end

@implementation FasTCashDrawerTableViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        foundDrawers = [[NSMutableArray alloc] init];
        currentHostName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"FasTPrintersTableViewController"] retain];
        testDrawer = [[FasTCashDrawer alloc] init];
        
        browser = [[NSNetServiceBrowser alloc] init];
        [browser setDelegate:self];
        [browser searchForServicesOfType:@"_cashdrawer._tcp." inDomain:@""];
        
        [self setTitle:NSLocalizedStringByKey(@"selectCashDrawer")];
    }
    return self;
}

- (void)dealloc
{
    [foundDrawers release];
    [testDrawer release];
    [browser release];
    [currentHostName release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [foundDrawers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNetService *drawer = foundDrawers[[indexPath row]];
    
    static NSString *cellId = @"drawerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
    }
    [[cell textLabel] setText:[drawer name]];
    [[cell detailTextLabel] setText:[drawer hostName]];
    if ([currentHostName isEqualToString:[drawer hostName]]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNetService *drawer = foundDrawers[[indexPath row]];
    [[NSUserDefaults standardUserDefaults] setValue:[drawer hostName] forKey:@"FasTCashDrawerHostNamePrefKey"];
    [[FasTCashDrawer defaultCashDrawer] updateHostNameFromPrefs];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [testDrawer setHostName:[foundDrawers[[indexPath row]] hostName]];
    [testDrawer identify];
}

#pragma mark - net service browser delegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [[aNetService retain] setDelegate:self];
    [aNetService resolveWithTimeout:5];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [foundDrawers removeObject:aNetService];
    if (!moreComing) [[self tableView] reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [foundDrawers addObject:sender];
    [sender release];
    [[self tableView] reloadData];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [sender release];
}

@end
