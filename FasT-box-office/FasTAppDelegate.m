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
    NSError *error = nil;
    
    iZettleSDKAuthorization *authProvider = [[iZettleSDKAuthorization alloc] initWithClientID:@"a9478ba6-4cda-4697-934b-ab2d812b6c2a" callbackURL:[NSURL URLWithString:@"fast-box-office://zettle-login-callback"] error:&error enforcedUserAccount:^NSString * _Nullable{
        return @"info@theater-kaisersesch.de";
    }];
    if (nil != error) {
        NSLog(@"%@", error);
    }
    [[iZettleSDK shared] startWithAuthorizationProvider:authProvider];

    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
        options.dsn = @"https://4e0a64484a7a497d8beec8da9a923abd@glitchtip.a0s.de/7";
    }];
    
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
