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
#import "FasTSettingsViewController.h"
#import "FasTPurchaseViewController.h"
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
    
    UIViewController *vc;
    vc = [[[FasTOrdersTableViewController alloc] init] autorelease];
    UINavigationController *ordersNavigationController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    vc = [[[FasTSearchViewController alloc] init] autorelease];
    UINavigationController *searchNavigationController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    vc = [[[FasTSettingsViewController alloc] init] autorelease];
    UINavigationController *settingsNavigationController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    vc = [[[FasTPurchaseViewController alloc] init] autorelease];
    UINavigationController *purchaseNavigationController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    UITabBarController *tbc = [[[UITabBarController alloc] init] autorelease];
    [tbc setDelegate:self];
    [tbc setViewControllers:@[purchaseNavigationController, searchNavigationController, ordersNavigationController, settingsNavigationController]];
    self.window.rootViewController = tbc;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setIdleTimerDisabled:YES];
}

#pragma mark tab bar controller delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    [(UINavigationController *)[tabBarController selectedViewController] popToRootViewControllerAnimated:[tabBarController selectedViewController] == viewController];
    return YES;
}

@end
