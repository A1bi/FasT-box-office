//
//  FasTOrderTicketTypesCell.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTOrderTicketTypesCell.h"

@interface FasTOrderTicketTypesCell ()

@end

@implementation FasTOrderTicketTypesCell

- (void)awakeFromNib {
    
}

- (IBAction)numberChanged:(UIStepper *)sender {
    _numberLabel.text = [NSString stringWithFormat:@"%li", (long)sender.value];
}

- (void)dealloc {
    [_nameLabel release];
    [_priceLabel release];
    [_numberLabel release];
    [_stepper release];
    [super dealloc];
}

@end
