//
//  FasTOrderViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 14.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrder;
@class FasTEvent;
@class FasTStepViewController;
@class MBProgressHUD;

@class FasTOrderViewController;

@protocol FasTOrderViewControllerDelegate <NSObject>

- (void)dismissorderViewController:(FasTOrderViewController *)ovc finished:(BOOL)finished;
- (void)orderInViewControllerExpired:(FasTOrderViewController *)ovc;

@end

@interface FasTOrderViewController : UIViewController <UIAlertViewDelegate>
{
    FasTOrder *order;
	UINavigationController *nvc;
    int currentStepIndex;
    NSArray *stepControllers;
    FasTStepViewController *currentStepController;
    id<FasTOrderViewControllerDelegate> delegate;
    
	IBOutlet UIButton *nextBtn;
	IBOutlet UIButton *prevBtn;
}

@property (nonatomic, readonly) FasTOrder *order;
@property (nonatomic, assign) id<FasTOrderViewControllerDelegate> delegate;

- (IBAction)nextTapped:(id)sender;
- (IBAction)prevTapped:(id)sender;

- (FasTEvent *)event;
- (void)updateNextButton;
- (void)toggleWaitingSpinner:(BOOL)toggle;
- (void)resetSeating;

@end
