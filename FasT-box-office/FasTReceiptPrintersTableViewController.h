//
//  FasTCashDrawerTableViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EPSPrinter;

@interface FasTReceiptPrintersTableViewController : UITableViewController <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSMutableArray *_foundPrinters;
    NSNetServiceBrowser *_browser;
    NSString *_currentHostName;
}

@end
