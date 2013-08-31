//
//  FasTOrderDetailsViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrderDetailsViewController.h"
#import "FasTTicketsViewController.h"
#import "FasTOrder.h"
#import "FasTApi.h"
#import "FasTFormatter.h"
#import "FasTTicketPrinter.h"
#import "MBProgressHUD.h"

@interface FasTOrderDetailsViewController ()

- (NSArray *)getRowForIndexPath:(NSIndexPath *)indexPath;
- (void)pay;
- (void)printTickets;

@end

@implementation FasTOrderDetailsViewController

- (id)initWithOrderNumber:(NSString *)n
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        number = [n retain];
        
        [self setTitle:NSLocalizedStringByKey(@"orderDetailsTitle")];
    }
    return self;
}

- (void)dealloc
{
    [sections release];
    [number release];
    [order release];
    [super dealloc];
}

- (void)viewDidLoad
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
    
    [[FasTApi defaultApi] getOrderWithNumber:number callback:^(FasTOrder *o) {
        [hud hide:YES];
        if (!o) {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedStringByKey(@"orderNotFoundTitle") message:NSLocalizedStringByKey(@"orderNotFoundDetails") delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
            [alert show];
            return;
        }
        
        [order release];
        order = [o retain];
        
        [sections release];
        sections = [@[
                        @{@"title": NSLocalizedStringByKey(@"general"), @"rows": @[
                            @[NSLocalizedStringByKey(@"order"), [order number]],
                            @[NSLocalizedStringByKey(@"name"), [order fullNameWithLastNameFirst:NO]],
                            @[NSLocalizedStringByKey(@"orderedAt"), [NSDateFormatter localizedStringFromDate:[order created] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]]
                        ]},
                        @{@"title": NSLocalizedStringByKey(@"details"), @"rows": @[
                            @[NSLocalizedStringByKey(@"tickets"), [NSString stringWithFormat:@"%i", [[order tickets] count]], @"tickets"],
                            @[NSLocalizedStringByKey(@"totalPrice"), [FasTFormatter stringForPrice:[order total]]],
                            @[NSLocalizedStringByKey(@"paid"), NSLocalizedStringByKey([order paid] ? @"yes" : @"no"), @"paid"]
                        ]}
                    ] retain];
        
        SEL btnSelector;
        NSString *btnText;
        if (![order paid]) {
            btnSelector = @selector(pay);
            btnText = NSLocalizedStringByKey(@"pay");
        } else {
            btnSelector = @selector(printTickets);
            btnText = NSLocalizedStringByKey(@"printTickets");
        }
        UIBarButtonItem *btn = [[[UIBarButtonItem alloc] initWithTitle:btnText style:UIBarButtonItemStyleBordered target:self action:btnSelector] autorelease];
        [[self navigationItem] setRightBarButtonItem:btn];
        
        [[self tableView] reloadData];
        [self setTitle:[NSString stringWithFormat:NSLocalizedStringByKey(@"orderDetailsTitleNumber"), [order number]]];
    }];
}

- (NSArray *)getRowForIndexPath:(NSIndexPath *)indexPath
{
    return sections[[indexPath section]][@"rows"][[indexPath row]];
}

- (void)pay
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTPurchaseControllerAddOrderToPay" object:nil userInfo:@{ @"order": order }];
}

- (void)printTickets
{
    [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:order];
    [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return sections[section][@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"detailsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:cellId] autorelease];
    }
    NSArray *row = [self getRowForIndexPath:indexPath];
    [[cell textLabel] setText:row[0]];
    [[cell detailTextLabel] setText:row[1]];
    UITableViewCellAccessoryType type = UITableViewCellAccessoryNone;
    UIColor *color = [UIColor whiteColor];
    if ([row count] > 2) {
        if ([row[2] isEqualToString:@"tickets"]) type = UITableViewCellAccessoryDisclosureIndicator;
        if ([row[2] isEqualToString:@"paid"] && ![order paid]) color = [UIColor redColor];
    }
    [cell setBackgroundColor:color];
    [cell setAccessoryType:type];
    
    return cell;
}

#pragma mark table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *row = [self getRowForIndexPath:indexPath];
    if ([row count] > 2 && [row[2] isEqualToString:@"tickets"]) {
        FasTTicketsViewController *tickets = [[[FasTTicketsViewController alloc] initWithTickets:[order tickets]] autorelease];
        [[self navigationController] pushViewController:tickets animated:YES];
    }
}

#pragma mark ui alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
