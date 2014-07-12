//
//  FasTMainViewControllerSegue.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 07.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTMainViewControllerSegue.h"
#import "FasTMainViewController.h"

@implementation FasTMainViewControllerSegue

- (void)perform
{
    FasTMainViewController *main = (FasTMainViewController *)self.sourceViewController;
    UIViewController *dst = self.destinationViewController;
    
    for (UIView *view in main.containerView.subviews) {
        [view removeFromSuperview];
    }
    [main.currentViewController removeFromParentViewController];
    
    [main.containerView addSubview:dst.view];
    main.currentViewController = dst;
    [main addChildViewController:dst];
}

@end
