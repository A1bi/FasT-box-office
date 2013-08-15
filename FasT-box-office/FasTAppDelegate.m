//
//  FasTAppDelegate.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTOrdersTableViewController.h"
#import "FasTSearchViewController.h"
#import "FasTApi.h"

@implementation FasTAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self.window makeKeyAndVisible];
    
    NSString *clientId = [[NSUserDefaults standardUserDefaults] valueForKey:@"boxOfficeId"];
    if (clientId && [clientId length] > 0) {
        [FasTApi defaultApiWithClientType:@"seating" clientId:clientId];
        [[FasTApi defaultApi] initNodeConnection];
    }
    
    FasTOrdersTableViewController *ordersController = [[[FasTOrdersTableViewController alloc] init] autorelease];
    UINavigationController *ordersNavigationController = [[[UINavigationController alloc] initWithRootViewController:ordersController] autorelease];
    
    FasTSearchViewController *searchController = [[[FasTSearchViewController alloc] init] autorelease];
    UINavigationController *searchNavigationController = [[[UINavigationController alloc] initWithRootViewController:searchController] autorelease];
    
    UITabBarController *tbc = [[[UITabBarController alloc] init] autorelease];
    [tbc setDelegate:self];
    [tbc setViewControllers:@[searchNavigationController, ordersNavigationController]];
    self.window.rootViewController = tbc;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setIdleTimerDisabled:YES];
}

#pragma mark tab bar controller delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [[tabBarController navigationController] popToRootViewControllerAnimated:NO];
}

@end
