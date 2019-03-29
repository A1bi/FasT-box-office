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

- (instancetype)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
{
    FasTMainViewController *main = (FasTMainViewController *)source;
    UIViewController *vc = main.containedViewControllers[identifier];
    if (!vc) {
        main.containedViewControllers[identifier] = destination;
    } else {
        destination = vc;
    }
    return [super initWithIdentifier:identifier source:source destination:destination];
}

- (void)perform
{
    FasTMainViewController *main = (FasTMainViewController *)self.sourceViewController;
    UIViewController *dst = self.destinationViewController;
    
    if (main.currentViewController == dst) {
        if ([dst isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController *)dst popToRootViewControllerAnimated:YES];
        }
    } else {
        [main.currentViewController willMoveToParentViewController:nil];
        [main.currentViewController.view removeFromSuperview];
        [main.currentViewController removeFromParentViewController];
        
        UIView *dstView = dst.view;
        CGRect frame = dstView.frame;
        frame.size = main.containerView.frame.size;
        dstView.frame = frame;
        [main.containerView addSubview:dstView];
        [main addChildViewController:dst];
        [dst didMoveToParentViewController:main];
        main.currentViewController = dst;
    }
}

@end
