//
//  FasTPurchasePaymentViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTPurchasePaymentViewController : UIViewController

@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (retain, nonatomic) IBOutlet UILabel *closeDrawerNoticeLabel;
@property (retain, nonatomic) IBOutlet UIButton *finishBtn;
@property (nonatomic, assign) float total;

@end
