//
//  FasTSelectedProductTableViewCell.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTSelectedProductTableViewCell;

@protocol FasTSelectedProductTableViewCellDelegate <NSObject>

- (void)selectedProductCellChangedNumber:(FasTSelectedProductTableViewCell *)cell;

@end

@interface FasTSelectedProductTableViewCell : UITableViewCell
{
    NSInteger number;
    NSDictionary *productInfo;
    id<FasTSelectedProductTableViewCellDelegate> delegate;
}

@property (assign, nonatomic) NSInteger number;
@property (assign, nonatomic) NSDictionary *productInfo;
@property (retain, nonatomic) IBOutlet UILabel *nameLabel;
@property (retain, nonatomic) IBOutlet UILabel *numberLabel;
@property (retain, nonatomic) IBOutlet UIStepper *numberStepper;
@property (retain, nonatomic) IBOutlet UILabel *totalLabel;
@property (assign, nonatomic) id<FasTSelectedProductTableViewCellDelegate> delegate;

- (IBAction)stepperChangedNumber:(id)sender;

@end
