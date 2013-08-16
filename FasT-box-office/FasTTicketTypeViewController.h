//
//  FasTTicketTypeViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 15.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTTicketType;

@interface FasTTicketTypeViewController : UIViewController
{
	FasTTicketType *type;
    NSInteger number;
    float total;
	
	IBOutlet UILabel *nameLabel;
	IBOutlet UILabel *infoLabel;
	IBOutlet UILabel *priceLabel;
	IBOutlet UILabel *numberLabel;
	IBOutlet UILabel *totalLabel;
}

@property (nonatomic, readonly) FasTTicketType *type;
@property (nonatomic, readonly) NSInteger number;
@property (nonatomic, readonly) float total;
@property (nonatomic, assign) id delegate;

- (IBAction)numberChanged:(UIStepper *)stepper;

- (id)initWithType:(FasTTicketType *)t;

@end
