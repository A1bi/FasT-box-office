//
//  FasTReportBillViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 22.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FasTReportBillViewControllerDelegate <NSObject>

@optional
- (void)dismissBillControllerWithSuccess:(BOOL)success;

@end

@interface FasTReportBillViewController : UIViewController

@property (assign) id<FasTReportBillViewControllerDelegate> delegate;

@end
