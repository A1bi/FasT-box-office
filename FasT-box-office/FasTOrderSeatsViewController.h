//
//  FasTSeatsViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTSeatingView.h"

@interface FasTOrderSeatsViewController : UIViewController <FasTSeatingViewDelegate>

@property (nonatomic, retain) IBOutlet FasTSeatingView *seatingView;

- (IBAction)placeOrder:(id)sender;

@end
