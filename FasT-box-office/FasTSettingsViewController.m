//
//  FasTSettingsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSettingsViewController.h"
#import "FasTConstants.h"
#import <iZettleSDK/iZettleSDK.h>

@interface FasTSettingsViewController ()

@end

@implementation FasTSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSString *descriptionKey;
    if ([cell.reuseIdentifier isEqualToString:@"ticketPrinterSettingCell"]) {
        descriptionKey = FasTTicketPrinterDescriptionPrefKey;
    } else {
        descriptionKey = @"FasTReceiptPrinterHostname";
    }
    
    NSString *deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:descriptionKey];
    [[cell detailTextLabel] setText:deviceName ? deviceName : NSLocalizedStringByKey(@"select")];
    
    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"electronicPaymentSettingCell"]) {
        [[iZettleSDK shared] presentSettingsFromViewController:self];
    }
}

@end
