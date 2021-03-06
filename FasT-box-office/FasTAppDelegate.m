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
@import iZettleSDK;
@import AFNetworking;
@import Sentry;

@implementation FasTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    [[iZettleSDK shared] startWithAPIKey:@"360E8DAABB8C8283D1F4B0D79CDB0B55"];

    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    NSError *error = nil;
    SentryClient *client = [[[SentryClient alloc] initWithDsn:@"https://5af12ad54ae04c27b41df3485083d378@sentry.a0s.de/6" didFailWithError:&error] autorelease];
    SentryClient.sharedClient = client;
    [SentryClient.sharedClient startCrashHandlerWithError:&error];
    if (nil != error) {
        NSLog(@"%@", error);
    }
    
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
