//
//  FasTSettingsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSettingsViewController.h"
#import "FasTConstants.h"

@interface FasTSettingsViewController ()

@end

@implementation FasTSettingsViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"settingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId] autorelease];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    NSString *descriptionKey, *i18nKey;
    if ([indexPath row] == 0) {
        descriptionKey = FasTPrinterDescriptionPrefKey;
        i18nKey = @"printer";
    } else {
        descriptionKey = @"FasTCashDrawerHostNamePrefKey";
        i18nKey = @"cashDrawer";
    }
    [[cell textLabel] setText:NSLocalizedStringByKey(i18nKey)];
    NSString *deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:descriptionKey];
    [[cell detailTextLabel] setText:deviceName ? deviceName : NSLocalizedStringByKey(@"select")];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *vc = [[[NSClassFromString([indexPath row] == 0 ? @"FasTPrintersTableViewController" : @"FasTCashDrawerTableViewController") alloc] init] autorelease];
    [[self navigationController] pushViewController:vc animated:YES];
}

@end
