//
//  FasTPurchasePaymentViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTPurchasePaymentViewController.h"
#import "FasTPurchaseViewController.h"
#import "FasTFormatter.h"

@interface FasTPurchasePaymentViewController ()

- (void)setDrawerClosed:(BOOL)toggle;

@end

@implementation FasTPurchasePaymentViewController

- (void)dealloc
{
    [_totalLabel release];
    [_closeDrawerNoticeLabel release];
    [_finishBtn release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _totalLabel.text = [FasTFormatter stringForPrice:_total];
    [self setDrawerClosed:YES];
    [[EPSPrinter sharedPrinter] setDelegate:self];
    [[EPSPrinter sharedPrinter] openCashDrawer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[EPSPrinter sharedPrinter] setDelegate:nil];
}

- (void)setDrawerClosed:(BOOL)toggle
{
    _closeDrawerNoticeLabel.hidden = toggle;
    _finishBtn.hidden = !toggle;
}

- (IBAction)finishBtnTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [_delegate dismissedPurchasePaymentViewController];
}

#pragma mark eps printer delegate

- (void)printer:(EPSPrinter *)printer drawerOpen:(BOOL)drawerOpen
{
    if (!drawerOpen) [self finishBtnTapped:nil];
}

@end