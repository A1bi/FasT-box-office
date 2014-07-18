//
//  FasTPurchasePaymentViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FasTPurchasePaymentViewControllerDelegate <NSObject>

@optional

- (void)dismissedPurchasePaymentViewController;

@end

@interface FasTPurchasePaymentViewController : UIViewController

@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (retain, nonatomic) IBOutlet UILabel *closeDrawerNoticeLabel;
@property (retain, nonatomic) IBOutlet UIButton *finishBtn;
@property (nonatomic, assign) id<FasTPurchasePaymentViewControllerDelegate> delegate;
@property (nonatomic, assign) float total;

- (IBAction)finishBtnTapped:(id)sender;

@end
