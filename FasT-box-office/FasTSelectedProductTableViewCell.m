//
//  FasTSelectedProductTableViewCell.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSelectedProductTableViewCell.h"
#import "FasTFormatter.h"

@implementation FasTSelectedProductTableViewCell

@synthesize number, productInfo, delegate;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setNumber:1];
    }
    return self;
}

- (void)dealloc
{
    [_nameLabel release];
    [_numberLabel release];
    [_numberStepper release];
    [_totalLabel release];
    [super dealloc];
}

- (void)setNumber:(NSInteger)n
{
    number = n;
    [[self numberLabel] setText:[NSString stringWithFormat:@"%d", number]];
    [[self totalLabel] setText:[FasTFormatter stringForPrice:([[self numberStepper] isHidden] ? 1 : number) * [productInfo[@"price"] floatValue]]];
    [[self numberStepper] setValue:number];
}

- (IBAction)stepperChangedNumber:(UIStepper *)sender
{
    [self setNumber:[sender value]];
    [delegate selectedProductCellChangedNumber:self];
}

- (void)enableOrderStyle:(BOOL)enable
{
    [[self numberStepper] setHidden:enable];
}

@end
