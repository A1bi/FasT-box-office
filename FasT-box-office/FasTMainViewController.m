//
//  FasTMainViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 07.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTMainViewController.h"

@interface FasTMainViewController ()

@end

@implementation FasTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self performSegueWithIdentifier:@"PurchaseSegue" sender:nil];
    
    CALayer *layer = _navView.layer;
    layer.shadowOffset = CGSizeMake(1, 1);
    layer.shadowColor = [[UIColor blackColor] CGColor];
    layer.shadowRadius = 4.0f;
    layer.shadowOpacity = 0.80f;
    layer.shadowPath = [UIBezierPath bezierPathWithRect:layer.bounds].CGPath;
}

- (void)dealloc
{
    [_containerView release];
    [_navView release];
    [super dealloc];
}

@end
