//
//  FasTPurchaseViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTOrderViewController.h"

@interface FasTPurchaseViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FasTOrderViewControllerDelegate>
{
    NSArray *_availableProducts;
    NSMutableArray *_selectedProducts;
    float _total;
    FasTOrderViewController *orderController;
    NSMutableArray *ordersToPay;
}

@property (retain, nonatomic) IBOutlet UITableView *selectedProductsTable;
@property (retain, nonatomic) IBOutlet UITableView *availableProductsTable;
@property (retain, nonatomic) IBOutlet UILabel *totalLabel;

- (IBAction)openCashDrawer;
- (IBAction)finishPurchase:(id)sender;
- (IBAction)clearPurchase:(id)sender;

@end
