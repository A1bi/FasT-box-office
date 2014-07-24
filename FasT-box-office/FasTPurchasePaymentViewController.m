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
#import "FasTCartItem.h"

@interface FasTPurchasePaymentViewController ()

- (void)setDrawerClosed:(BOOL)toggle;

@end

@implementation FasTPurchasePaymentViewController

- (void)dealloc
{
    [_totalLabel release];
    [_closeDrawerNoticeLabel release];
    [_finishBtn release];
    [_cartItems release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    float total = 0;
    for (FasTCartItem *cartItem in _cartItems) {
        total += cartItem.total;
    }
    
    _totalLabel.text = [FasTFormatter stringForPrice:total];
    [self setDrawerClosed:YES];
    
    FasTReceiptPrinter *printer = [FasTReceiptPrinter sharedPrinter];
    [printer setDelegate:self];
    [printer openCashDrawer];
    [printer printReceiptForCartItems:_cartItems];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ESCPrinter sharedPrinter] setDelegate:nil];
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

#pragma mark ESCPrinter delegate

- (void)printer:(ESCPrinter *)printer drawerOpen:(BOOL)drawerOpen
{
    if (!drawerOpen) [self finishBtnTapped:nil];
}

@end
