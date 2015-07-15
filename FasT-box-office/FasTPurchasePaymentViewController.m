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
#import "FasTApi.h"
#import "MBProgressHUD.h"
#import <iZettleSDK/iZettleSDK.h>

@interface FasTPurchasePaymentViewController ()
{
    float _cashGiven, _total;
    BOOL _finished;
}

- (void)finish;
- (void)savePurchase;
- (void)updateGivenLabel;

@end

@implementation FasTPurchasePaymentViewController

- (void)dealloc
{
    [_totalLabel release];
    [_cartItems release];
    [_givenLabel release];
    [_changeLabel release];
    [_dismissBtn release];
    [_cancelBtn release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *total = [_cartItems valueForKeyPath:@"@sum.total"];
    _total = total.floatValue;
    _totalLabel.text = [FasTFormatter stringForPrice:_total];
    _finished = NO;
    [self updateGivenLabel];
    
    [[FasTReceiptPrinter sharedPrinter] setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ESCPrinter sharedPrinter] setDelegate:nil];
}

- (IBAction)printReceipt
{
    if (_finished) {
        [[FasTReceiptPrinter sharedPrinter] printReceiptForCartItems:_cartItems];
    }
}

- (IBAction)numKeyTapped:(UIButton *)sender
{
    if (_finished) return;
    
    NSString *numKey = sender.titleLabel.text;
    _cashGiven = (_cashGiven * 100 * pow(10, numKey.length) + numKey.integerValue) / 100.0f;
    [self updateGivenLabel];
}

- (void)savePurchase
{
    NSMutableArray *items = [NSMutableArray array];
    
    for (FasTCartItem *item in _cartItems) {
        NSDictionary *itemData = @{ @"type": item.type, @"number": @(item.quantity), @"id": item.productId };
        [items addObject:itemData];
    }
    
    [[FasTApi defaultApi] finishPurchase:@{ @"items": items }];
}

- (IBAction)resetCash
{
    if (_finished) return;
    
    _cashGiven = 0;
    [self updateGivenLabel];
}

- (void)updateGivenLabel
{
    self.givenLabel.text = [FasTFormatter stringForPrice:_cashGiven];
    self.givenLabel.textColor = (_cashGiven >= _total) ? [UIColor greenColor] : [UIColor redColor];
}

- (void)payCash
{
    if (_finished || _cashGiven < _total) return;
    [self finish];
    
    float change = _cashGiven - _total;
    self.changeLabel.text = [FasTFormatter stringForPrice:change];
    self.changeLabel.hidden = NO;
    self.givenLabel.layer.opacity = 0.2f;
    
    [[FasTReceiptPrinter sharedPrinter] openCashDrawer];
}

- (void)payElectronically
{
    if (_finished || _total <= 0) return;
    
    NSDecimalNumber *total = [[[NSDecimalNumber alloc] initWithFloat:_total] autorelease];
    [[iZettleSDK shared] chargeAmount:total currency:nil reference:@"bla" presentFromViewController:self completion:^(iZettleSDKPaymentInfo *paymentInfo, NSError *error) {
        if (paymentInfo) {
            [self finish];
            [self printReceipt];
            self.givenLabel.hidden = YES;
        }
    }];
}

- (void)finish
{
    _finished = YES;
    self.cancelBtn.enabled = NO;
    self.dismissBtn.enabled = YES;
    [self savePurchase];
}

- (IBAction)dismiss
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [_delegate dismissedPurchasePaymentViewControllerFinished:_finished];
}

#pragma mark ESCPrinter delegate

- (void)printer:(ESCPrinter *)printer drawerOpen:(BOOL)drawerOpen
{
    
}

@end
