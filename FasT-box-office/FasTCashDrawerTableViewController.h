//
//  FasTCashDrawerTableViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTCashDrawer;

@interface FasTCashDrawerTableViewController : UITableViewController <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSMutableArray *foundDrawers;
    NSNetServiceBrowser *browser;
    NSString *currentHostName;
    FasTCashDrawer *testDrawer;
}

@end
