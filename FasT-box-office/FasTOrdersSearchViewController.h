//
//  FasTOrdersTableViewController.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FasTOrdersSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *orders;
    NSString *highlightedTicketId;
}

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UITextField *searchField;

- (IBAction)didEnterSearchTerm:(UITextField *)sender;
- (void)clearFormAndResults;

@end
