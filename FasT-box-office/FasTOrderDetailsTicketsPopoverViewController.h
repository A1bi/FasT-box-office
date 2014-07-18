//
//  FasTOrderDetailsTicketsPopoverViewControllerTableViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTOrderDetailsTicketsPopoverViewController : UITableViewController
{
    NSMutableArray *_rows;
}

@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) NSArray *tickets;

@end
