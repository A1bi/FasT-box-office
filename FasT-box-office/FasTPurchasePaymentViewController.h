//
//  FasTPurchasePaymentViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTReceiptPrinter.h"

@protocol FasTPurchasePaymentViewControllerDelegate <NSObject>

@optional
- (void)paymentFinishedInPaymentViewController;
- (void)dismissedPurchasePaymentViewControllerFinished:(BOOL)finished;

@end

@interface FasTPurchasePaymentViewController : UIViewController <ESCPrinterDelegate>

@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (retain, nonatomic) IBOutlet UILabel *givenLabel;
@property (retain, nonatomic) IBOutlet UILabel *changeLabel;
@property (retain, nonatomic) IBOutlet UILabel *cashDrawerAlertLabel;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *cancelBtn;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *dismissBtn;
@property (nonatomic, assign) id<FasTPurchasePaymentViewControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *cartItems;

- (IBAction)printReceipt;
- (IBAction)numKeyTapped:(UIButton *)sender;
- (IBAction)resetCash;
- (IBAction)payCash;
- (IBAction)payElectronically;
- (IBAction)dismiss;

@end
