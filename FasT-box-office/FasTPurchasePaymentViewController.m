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
@import MBProgressHUD;
@import iZettleSDK;

@interface FasTPurchasePaymentViewController ()
{
    float _cashGiven, _total;
    BOOL _finished;
    iZettleSDKPaymentInfo *_electronicPaymentInfo;
}

- (void)finish;
- (void)savePurchaseWithPayMethod:(NSString *)payMethod;
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
    [_electronicPaymentInfo release];
    [_cashDrawerAlertLabel release];
    [_electronicPaymentBtn release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *total = [_cartItems valueForKeyPath:@"@sum.total"];
    _total = total.floatValue;
    _totalLabel.text = [FasTFormatter stringForPrice:_total];
    _electronicPaymentBtn.hidden = _total <= 0;
    _finished = NO;
    [self updateGivenLabel];
    
    [[FasTReceiptPrinter sharedPrinter] setDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ESCPrinter sharedPrinter] setDelegate:nil];
}

- (void)setCartItems:(NSArray *)cartItems
{
    [_cartItems release];
    _cartItems = [cartItems copy];
}

- (IBAction)printReceipt
{
    if (_finished) {
        if (_electronicPaymentInfo) {
            [[FasTReceiptPrinter sharedPrinter] printReceiptForCartItems:_cartItems withElectronicCashPaymentInfo:_electronicPaymentInfo];
        } else {
            [[FasTReceiptPrinter sharedPrinter] printReceiptForCartItems:_cartItems withCashPaymentInfo:@{ @"given": @(_cashGiven), @"change": @(_cashGiven - _total) }];
        }
    }
}

- (IBAction)numKeyTapped:(UIButton *)sender
{
    if (_finished) return;
    
    NSString *numKey = sender.titleLabel.text;
    _cashGiven = (_cashGiven * 100 * pow(10, numKey.length) + numKey.integerValue) / 100.0f;
    [self updateGivenLabel];
}

- (void)savePurchaseWithPayMethod:(NSString *)payMethod
{
    NSMutableArray *items = [NSMutableArray array];
    
    for (FasTCartItem *item in _cartItems) {
        [items addObject:item.apiInfo];
    }
    
    [[FasTApi defaultApi] finishPurchase:@{ @"items": items, @"pay_method": payMethod }];
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
    self.givenLabel.textColor = (_cashGiven >= _total) ? [UIColor systemGreenColor] : [UIColor systemRedColor];
}

- (void)payCash
{
    if (_finished || _cashGiven < _total) return;
    [self finish];
    [self savePurchaseWithPayMethod:@"cash"];
    
    float change = _cashGiven - _total;
    self.changeLabel.text = [FasTFormatter stringForPrice:change];
    self.changeLabel.hidden = NO;
    self.givenLabel.layer.opacity = 0.2f;
    
    [[FasTReceiptPrinter sharedPrinter] openCashDrawer];
}

- (void)payElectronically
{
    if (_finished) return;
    
    NSDecimalNumber *total = [[[NSDecimalNumber alloc] initWithFloat:_total] autorelease];
    [[iZettleSDK shared] chargeAmount:total enableTipping:NO reference:@"Abendkasse" presentFromViewController:self completion:^(iZettleSDKPaymentInfo * _Nullable paymentInfo, NSError * _Nullable error) {
        if (paymentInfo) {
            [self finish];
            [self savePurchaseWithPayMethod:@"electronic_cash"];
            _electronicPaymentInfo = [paymentInfo retain];
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
    [self.delegate paymentFinishedInPaymentViewController];
}

- (IBAction)dismiss
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ESCPrinter delegate

- (void)printer:(ESCPrinter *)printer drawerOpen:(BOOL)drawerOpen
{
    _cashDrawerAlertLabel.hidden = !drawerOpen;
}

@end
