//
//  FasTOrderDetailsViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrder;

@interface FasTOrderDetailsViewController : UITableViewController <UIAlertViewDelegate>
{
    NSArray *_infoTableRows;
    NSDateFormatter *_dateFormatter;
    BOOL _selectAllTicketsToggle;
}

@property (nonatomic, retain) FasTOrder *order;
@property (nonatomic, retain) NSString *highlightedTicketId;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *ticketsPopoverBarButton;

- (IBAction)selectAllTickets:(id)sender;

@end
