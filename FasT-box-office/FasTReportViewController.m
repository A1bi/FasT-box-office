//
//  FasTReportViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 22.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTReportViewController.h"
#import "FasTApi.h"
#import "FasTFormatter.h"

@interface FasTReportViewController ()
{
    NSArray *products, *billings;
    float balance;
}

- (void)refreshData;

@end

@implementation FasTReportViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshData];
}

- (void)refreshData {
    [[FasTApi defaultApi] getResource:@"api/box_office" withAction:@"report" callback:^(NSDictionary *response) {
        [products release];
        products = [response[@"products"] retain];
        [billings release];
        billings = [response[@"billings"] retain];
        balance = ((NSNumber *)response[@"balance"]).floatValue;
        
        [self.tableView reloadData];
    }];
}

- (void)dismissBillControllerWithSuccess:(BOOL)success {
    [self dismissViewControllerAnimated:YES completion:NULL];
    if (success) {
        [self refreshData];
    }
}

- (void)dealloc {
    [products release];
    [billings release];
    [super dealloc];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FasTReportBillSegue"]) {
        FasTReportBillViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return products.count;
        case 1:
            return billings.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Heute verkaufte Produkte";
        case 1:
            return @"Heutige Kassenbuchungen";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return [NSString stringWithFormat:@"Aktueller Kassenstand: %@", [FasTFormatter stringForPrice:-balance]];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0: {
            NSDictionary *product = products[indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"productCell"];
            if (!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"productCell"] autorelease];
            }
            cell.textLabel.text = product[@"name"];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", product[@"number"]];
            return cell;
        }
        case 1: {
            NSDictionary *product = billings[indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"billingCell"];
            if (!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"billingCell"] autorelease];
            }
            cell.textLabel.text = product[@"reason"];
            float amount = ((NSNumber *)product[@"amount"]).floatValue;
            cell.detailTextLabel.text = [FasTFormatter stringForPrice:-amount];
            return cell;
        }
    }
    return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
}

@end
