//
//  FasTTicketsViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTTicketsViewController : UITableViewController <UIAlertViewDelegate>
{
    NSArray *tickets;
    UIBarButtonItem *printBtn;
}

- (id)initWithTickets:(NSArray *)t;

@end
