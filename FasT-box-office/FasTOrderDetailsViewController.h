//
//  FasTOrderDetailsViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrder;

@interface FasTOrderDetailsViewController : UITableViewController <UIPopoverControllerDelegate>

@property (nonatomic, retain) FasTOrder *order;
@property (nonatomic, retain) NSString *highlightedTicketId;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *ticketsPopoverBarButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *refundBarButton;

- (IBAction)selectAllTickets:(id)sender;
- (IBAction)openInSafari;
- (IBAction)refundBalance;

@end
