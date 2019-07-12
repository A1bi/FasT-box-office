//
//  FasTSeatsViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTSeatingView.h"

@interface FasTOrderSeatsViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIView *seatingView;

- (IBAction)placeOrder:(id)sender;
- (IBAction)rotateSeatingView;

@end
