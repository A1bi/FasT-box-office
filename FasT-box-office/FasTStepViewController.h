//
//  FasTStepViewController.h
//  FasT-retail
//
//  Created by Albrecht Oster on 14.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrderViewController;

@interface FasTStepViewController : UIViewController
{
    NSString *stepName;
    FasTOrderViewController *orderController;
}

@property (nonatomic, readonly) NSString *stepName;

- (id)initWithStepName:(NSString *)name orderController:(FasTOrderViewController *)oc;
- (id)initWithOrderController:(FasTOrderViewController *)oc;
- (BOOL)isValid;

@end
