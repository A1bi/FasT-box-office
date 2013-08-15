//
//  FasTOrderDetailsViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTOrder;

@interface FasTOrderDetailsViewController : UITableViewController <UIAlertViewDelegate>
{
    NSArray *sections;
    NSString *number;
    FasTOrder *order;
}

- (id)initWithOrderNumber:(NSString *)n;

@end
