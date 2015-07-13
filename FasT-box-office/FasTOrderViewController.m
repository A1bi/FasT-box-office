//
//  FasTOrderViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 12.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTOrderViewController.h"
#import "FasTOrder.h"
#import "FasTApi.h"

@interface FasTOrderViewController ()

- (void)addCancelBtnToViewController:(UIViewController *)vc;

@end

@implementation FasTOrderViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addCancelBtnToViewController:self.topViewController];
    
    self.order = [[[FasTOrder alloc] init] autorelease];
    
    [[FasTApi defaultApi] unlockSeats];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    
    [self addCancelBtnToViewController:viewController];
}

- (void)addCancelBtnToViewController:(UIViewController *)vc
{
    vc.navigationItem.rightBarButtonItem = _cancelBtn;
}

- (IBAction)cancel:(id)sender
{
    [[FasTApi defaultApi] resetSeating];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dealloc
{
    [super dealloc];
    [_order dealloc];
}

@end
