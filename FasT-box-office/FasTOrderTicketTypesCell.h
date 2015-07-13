//
//  FasTOrderTicketTypesCell.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTOrderTicketTypesCell : UITableViewCell

@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *priceLabel;
@property (retain, nonatomic) IBOutlet UILabel *numberLabel;
@property (retain, nonatomic) IBOutlet UIStepper *stepper;

- (IBAction)numberChanged:(UIStepper *)sender;

@end
