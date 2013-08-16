//
//  FasTTicketTypeViewController.m
//  FasT-retail
//
//  Created by Albrecht Oster on 15.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTTicketTypeViewController.h"
#import "FasTTicketTypesViewController.h"
#import "FasTTicketType.h"
#import "FasTFormatter.h"

@interface FasTTicketTypeViewController ()

@end

@implementation FasTTicketTypeViewController

@synthesize type, number, total, delegate;

- (id)initWithType:(FasTTicketType *)t
{
    self = [super init];
    if (self) {
        type = [t retain];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [nameLabel setText:[type name]];
	[infoLabel setText:[type info]];
	[priceLabel setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"ticketPriceEach"), [type localizedPrice]]];
}

- (void)dealloc
{
	[type release];
    
	[nameLabel release];
	[infoLabel release];
	[numberLabel release];
	[totalLabel release];
	[priceLabel release];
	[super dealloc];
}

#pragma mark actions

- (IBAction)numberChanged:(UIStepper *)stepper {
	number = (NSInteger)[stepper value];
	total = number * [type price];
	
	[numberLabel setText:[NSString stringWithFormat:@"%i", number]];
	[totalLabel setText:[FasTFormatter stringForPrice:total]];
	
	[(FasTTicketTypesViewController *)delegate changedTotalOfTicketType:self];
}

@end
