//
//  FasTAppDelegate.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTApi.h"
#import "EPSPrinter.h"

@implementation FasTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *clientId = [[NSUserDefaults standardUserDefaults] valueForKey:@"boxOfficeId"];
    if (clientId && [clientId length] > 0) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [FasTApi defaultApiWithClientType:@"seating" clientId:@"0"];
        [[FasTApi defaultApi] fetchCurrentEvent:NULL];
    NSString *receiptPrinterHostname = [defaults valueForKey:@"FasTReceiptPrinterHostname"];
    if (receiptPrinterHostname && receiptPrinterHostname.length) {
        [EPSPrinter initSharedPrinterWithHost:receiptPrinterHostname port:[[defaults valueForKey:@"FasTReceiptPrinterPort"] integerValue]];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setIdleTimerDisabled:YES];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
