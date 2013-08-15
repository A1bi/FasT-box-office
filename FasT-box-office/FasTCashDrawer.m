//
//  FasTCashDrawer.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTCashDrawer.h"
#import "MKNetworkKit.h"

static FasTCashDrawer *defaultCashDrawer = nil;

@interface FasTCashDrawer ()

- (void)makeRequest:(NSString *)request;

@end

@implementation FasTCashDrawer

+ (id)defaultCashDrawer
{
    if (!defaultCashDrawer) {
        defaultCashDrawer = [[super alloc] init];
        [defaultCashDrawer updateHostNameFromPrefs];
    }
    return defaultCashDrawer;
}

- (void)dealloc
{
    [netEngine release];
    [super dealloc];
}

- (void)setHostName:(NSString *)hostName
{
    [netEngine release];
    netEngine = [[MKNetworkEngine alloc] initWithHostName:hostName];
}

- (void)updateHostNameFromPrefs
{
    [self setHostName:[[NSUserDefaults standardUserDefaults] valueForKey:@"FasTCashDrawerHostNamePrefKey"]];
}

- (void)makeRequest:(NSString *)request
{
    MKNetworkOperation *op = [netEngine operationWithPath:@"/open.php" params:@{@"action": request}];
	[netEngine enqueueOperation:op];
}

- (void)identify
{
    [self makeRequest:@"identify"];
}

- (void)open
{
    [self makeRequest:@""];
}

@end
