//
//  FasTOrdersTableViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTOrdersListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *orders;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end
