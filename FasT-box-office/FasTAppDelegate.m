//
//  FasTAppDelegate.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTApi.h"
#import "FasTReceiptPrinter.h"
#import <iZettleSDK/iZettleSDK.h>

@implementation FasTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [FasTApi defaultApiWithClientType:@"seating" clientId:@"0"];
    [[FasTApi defaultApi] initNodeConnection];
    
    [[iZettleSDK shared] startWithAPIKey:@"360E8DAABB8C8283D1F4B0D79CDB0B55"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *receiptPrinterHostname = [defaults valueForKey:@"FasTReceiptPrinterHostname"];
    if (receiptPrinterHostname && receiptPrinterHostname.length) {
        [FasTReceiptPrinter initSharedPrinterWithHost:receiptPrinterHostname port:[[defaults valueForKey:@"FasTReceiptPrinterPort"] integerValue]];
    }
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setIdleTimerDisabled:YES];
    
    [[FasTReceiptPrinter sharedPrinter] connect];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[FasTReceiptPrinter sharedPrinter] disconnect];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
