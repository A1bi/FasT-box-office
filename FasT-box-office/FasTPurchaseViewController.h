//
//  FasTPurchaseViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTOrderViewController.h"
#import "FasTPurchasePaymentViewController.h"

@interface FasTPurchaseViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, FasTPurchasePaymentViewControllerDelegate, FasTOrderViewControllerDelegate>
{
    NSArray *_availableProducts;
    NSMutableArray *_cartItems;
    float _total;
    FasTOrderViewController *orderController;
    NSMutableArray *_ticketsToPay;
}

@property (retain, nonatomic) IBOutlet UITableView *cartItemsTable;
@property (retain, nonatomic) IBOutlet UITableView *availableProductsTable;
@property (retain, nonatomic) IBOutlet UILabel *totalLabel;

- (IBAction)openCashDrawer;
- (IBAction)clearPurchase:(id)sender;

@end
