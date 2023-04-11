//
//  FasTSettingsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSettingsViewController.h"
#import "FasTConstants.h"
@import iZettleSDK;

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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"FasT-box-office v%@ (%@)", version, build];
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"electronicPaymentSettingCell"]) {
        [[iZettleSDK shared] presentSettingsFromViewController:self];
    } else if ([[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"ticketPrinterSettingCell"]) {
        UIPrinterPickerController *printerPicker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
        printerPicker.delegate = self;
        [printerPicker presentAnimated:YES completionHandler:^(UIPrinterPickerController * _Nonnull printerPickerController, BOOL userDidSelect, NSError * _Nullable error) {
            if (userDidSelect && !error) {
                UIPrinter *printer = printerPickerController.selectedPrinter;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:printer.displayName forKey:FasTTicketPrinterUrlPrefKey];
                [defaults setObject:printer.URL.absoluteString forKey:FasTTicketPrinterUrlPrefKey];
            }
        }];
    }
}

#pragma mark - printer picker delegate

- (UIViewController *)printerPickerControllerParentViewController:(UIPrinterPickerController *)printerPickerController
{
    return self;
}

@end
