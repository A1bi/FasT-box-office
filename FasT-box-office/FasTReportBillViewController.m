//
//  FasTReportBillViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 22.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTReportBillViewController.h"
#import "FasTReportViewController.h"
#import "FasTApi.h"
@import MBProgressHUD;

@interface FasTReportBillViewController ()

@property (retain, nonatomic) IBOutlet UITextField *amountField;
@property (retain, nonatomic) IBOutlet UITextField *reasonField;

- (void)dismissWithSuccess:(BOOL)success;

@end

@implementation FasTReportBillViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.preferredContentSize = CGSizeMake(500, 250);
}

- (IBAction)submit:(id)sender {
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *amount = [formatter numberFromString:_amountField.text];
    
    if (amount.floatValue != 0) {
        amount = [NSNumber numberWithFloat:amount.floatValue * -1];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSDictionary *data = @{ @"amount": amount, @"reason": _reasonField.text };
        [[FasTApi defaultApi] postResource:@"api/box_office" withAction:@"bill" data:data callback:^(NSDictionary *response) {
            [hud hideAnimated:YES];
            [self dismissWithSuccess:YES];
        }];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissWithSuccess:NO];
}

- (void)dismissWithSuccess:(BOOL)success {
    [_delegate dismissBillControllerWithSuccess:success];
}

- (void)dealloc {
    [_amountField release];
    [_reasonField release];
    [super dealloc];
}
@end
