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
- (void)dismissedPurchasePaymentViewController;

@end

@interface FasTPurchasePaymentViewController : UIViewController <ESCPrinterDelegate>

@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (retain, nonatomic) IBOutlet UILabel *closeDrawerNoticeLabel;
@property (retain, nonatomic) IBOutlet UIButton *finishBtn;
@property (nonatomic, assign) id<FasTPurchasePaymentViewControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *cartItems;

- (IBAction)finishBtnTapped:(id)sender;
- (IBAction)printReceiptBtnTapped:(id)sender;

@end
