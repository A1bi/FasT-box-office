//
//  FasTMainViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 07.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTMainViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (assign, nonatomic) UIViewController *currentViewController;
@property (retain, nonatomic) IBOutlet UIView *navView;

@end
