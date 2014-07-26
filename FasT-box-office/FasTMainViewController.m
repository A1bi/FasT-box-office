//
//  FasTMainViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 07.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTMainViewController.h"
#import "FasTOrdersSearchViewController.h"

@interface FasTMainViewController ()

@end

@implementation FasTMainViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _containedViewControllers = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToPurchaseController) name:@"FasTSwitchToPurchaseController" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self switchToPurchaseController];
    
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
    [_containedViewControllers release];
    [super dealloc];
}

- (void)switchToPurchaseController
{
    [self performSegueWithIdentifier:@"PurchaseSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OrdersSearchSegue"]) {
        FasTOrdersSearchViewController *search = [(UINavigationController *)segue.destinationViewController viewControllers][0];
        [search clearFormAndResults];
    }
}

@end
