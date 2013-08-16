//
//  FasTPurchaseViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTSelectedProductTableViewCell.h"

@interface FasTPurchaseViewController : UIViewController <UITableViewDataSource, FasTSelectedProductTableViewCellDelegate>
{
    NSArray *products;
    NSMutableDictionary *selectedProducts;
    float total;
}

@property (retain, nonatomic) IBOutlet UIButton *buyTicketsBtn;
@property (retain, nonatomic) IBOutlet UITableView *selectedProductsTable;
@property (retain, nonatomic) IBOutlet UILabel *totalLabel;

- (IBAction)openCashDrawer;
- (IBAction)finishPurchase:(id)sender;
- (IBAction)clearPurchase:(id)sender;

@end
