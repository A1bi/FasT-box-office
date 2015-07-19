//
//  FasTOrderViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrder;

@protocol FasTOrderViewControllerDelegate <UINavigationControllerDelegate>

- (void)didPlaceOrder:(FasTOrder *)order;

@end

@interface FasTOrderViewController : UINavigationController

@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelBtn;
@property (nonatomic, assign) IBOutlet id<FasTOrderViewControllerDelegate> delegate;
@property (nonatomic, retain) FasTOrder *order;

- (IBAction)cancel:(id)sender;

@end
