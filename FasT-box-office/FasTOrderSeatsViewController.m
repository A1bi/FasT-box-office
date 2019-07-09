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

#define DegreesToRadians(x) ((x) * M_PI / 180.0)

@interface FasTOrderSeatsViewController ()
{
    FasTOrder *_order;
    FasTEventDate *_date;
    NSMutableArray *_chosenSeats;
    BOOL seatingViewRotated;
    
    UIAlertView *errorAlert;
}

- (void)updateSeatsWithInfo:(NSDictionary *)seats;
- (void)updateSeatsWithNotification:(NSNotification *)note;
- (void)updateSeats;

@end

@implementation FasTOrderSeatsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _order = ((FasTOrderViewController *)self.navigationController).order;
    _chosenSeats = [[NSMutableArray array] retain];
    
    seatingViewRotated = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    FasTEventDate *date = _order.date;
    if (_date != date) {
        _date = date;
        [self updateSeats];
    }
    
    [[FasTApi defaultApi] setDate:_date.dateId numberOfSeats:_order.numberOfTickets callback:^(NSDictionary *response) {
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [errorAlert dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [errorAlert release];
    [_seatingView release];
    [_chosenSeats release];
    [super dealloc];
}

#pragma mark class methods

- (void)updateSeatsWithInfo:(NSDictionary *)seats
{
    NSDictionary *dateSeats = seats[_date.dateId];
    if (!dateSeats) return;
    
    for (NSString *seatId in dateSeats) {
        FasTSeat *seat = dateSeats[seatId];
        if (![seat isKindOfClass:[FasTSeat class]]) {
            seat = _date.event.seats[_date.dateId][seatId];
        }
        [_seatingView updatedSeat:seat];
        
        if ([seat chosen]) {
            [_chosenSeats addObject:seat];
        } else {
            [_chosenSeats removeObject:seat];
        }
    }
}

- (void)updateSeatsWithNotification:(NSNotification *)note
{
    [self updateSeatsWithInfo:[note userInfo]];
}

- (void)updateSeats
{
    [_chosenSeats removeAllObjects];
    [self updateSeatsWithInfo:_date.event.seats];
}

- (IBAction)placeOrder:(id)sender
{
    if (_chosenSeats.count == _order.tickets.count) {
        [((FasTOrderViewController *)self.navigationController).delegate didPlaceOrder:_order];
    } else {
        NSString *message = [NSString stringWithFormat:NSLocalizedStringByKey(@"notEnoughSeatsErrorMessage"), _order.tickets.count];
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedStringByKey(@"notEnoughSeatsErrorTitle") message:message delegate:nil cancelButtonTitle:NSLocalizedStringByKey(@"dismissAlert") otherButtonTitles:nil] autorelease];
        [alert show];
    }
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

#pragma mark seating delegate methods

- (void)didChooseSeatView:(FasTSeatView *)seatView
{
    [[FasTApi defaultApi] chooseSeatWithId:[seatView seatId]];
}

@end
