//
//  FasTMainViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 07.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTMainViewController.h"

@interface FasTMainViewController ()

@end

@implementation FasTMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self performSegueWithIdentifier:@"PurchaseSegue" sender:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc
{
    [_containerView release];
    [super dealloc];
}

@end
