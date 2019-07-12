//
//  FasTSeatsViewController.m
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FasTOrderSeatsViewController.h"
#import "FasTOrderViewController.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTSeat.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTApi.h"
#import "FasTSeatingView.h"

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@interface FasTOrderSeatsViewController ()
{
    FasTOrder *_order;
    BOOL seatingViewRotated;
}

@end

@implementation FasTOrderSeatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _order = ((FasTOrderViewController *)self.navigationController).order;

    FasTSeatingView *seatingView = [[FasTApi defaultApi] seatingView];
    [_seatingView addSubview:seatingView];
    seatingView.frame = CGRectMake(0, 0, _seatingView.frame.size.width, _seatingView.frame.size.height);
    seatingView.bounds = CGRectMake(0, 0, _seatingView.frame.size.width, _seatingView.frame.size.height);
    
    seatingViewRotated = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[[FasTApi defaultApi] seatingView] setDate:_order.date numberOfSeats:_order.numberOfTickets];
}

- (void)dealloc {
    [_seatingView release];
    [super dealloc];
}

#pragma mark class methods

- (IBAction)placeOrder:(id)sender
{
    [[[FasTApi defaultApi] seatingView] validate:^(BOOL valid) {
        if (valid && false) {
            [((FasTOrderViewController *)self.navigationController).delegate didPlaceOrder:_order];
        }
    }];
}

- (IBAction)rotateSeatingView
{
    [UIView beginAnimations:@"rotate" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    seatingViewRotated = !seatingViewRotated;
    CGFloat angle = seatingViewRotated ? DegreesToRadians(180) : 0;
    _seatingView.transform = CGAffineTransformMakeRotation(angle);
    
    [UIView commitAnimations];
}

@end
