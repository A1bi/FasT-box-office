//
//  FasTTicketsViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTStepViewController.h"

@class FasTTicketTypeViewController;

@interface FasTTicketTypesViewController : FasTStepViewController
{
	NSArray *typeVCs;
    NSInteger numberOfTickets;
    
    IBOutlet UILabel *totalLabel;
    IBOutlet UIView *ticketsView;
}

- (void)changedTotalOfTicketType:(FasTTicketTypeViewController *)t;

@end
