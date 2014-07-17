//
//  FasTPurchaseViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTPurchaseViewController.h"
#import "FasTPurchasePaymentViewController.h"
#import "FasTMainViewController.h"
#import "FasTCashDrawer.h"
#import "FasTFormatter.h"
#import "FasTApi.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTEventDate.h"
#import "FasTTicketPrinter.h"
#import "MBProgressHUD.h"

@interface FasTPurchaseViewController ()

- (NSDictionary *)productInfoForIndexPath:(NSIndexPath *)indexPath;
- (void)updateSelectedProductsTableAndTotal;
- (void)updateTotal;
- (void)updateSelectedProductsTable;
- (void)finishPurchase;
- (void)finishedPurchase;
- (void)showAlertWithTitle:(NSString *)title details:(NSString *)details;
- (void)receivedTicketsToPay:(NSNotification *)note;

@end

@implementation FasTPurchaseViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _availableProducts = [@[
                      @{@"type": @"product", @"id": @"1", @"name": @"Programmheft", @"price": @(1)},
                      @{@"type": @"product", @"id": @"2", @"name": @"Regenponcho", @"price": @(1)}
                      ] retain];
        _selectedProducts = [[NSMutableArray alloc] init];
        _ticketsToPay = [[NSMutableArray alloc] init];
        
        orderController = [[FasTOrderViewController alloc] init];
        [orderController setDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTicketsToPay:) name:@"FasTPurchaseControllerAddTicketsToPay" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_availableProducts release];
    [_selectedProducts release];
    [_selectedProductsTable release];
    [_totalLabel release];
    [_availableProductsTable release];
    [super dealloc];
}

- (void)viewDidLoad
{    
    [self updateTotal];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FasTPurchasePaymentSegue"]) {
        FasTPurchasePaymentViewController *payment = segue.destinationViewController;
        [payment setTotal:_total];
        //[self finishedPurchase];
    }
}

- (NSDictionary *)productInfoForIndexPath:(NSIndexPath *)indexPath
{
    return _availableProducts[indexPath.row - 1];
}

- (void)updateTotal
{
    _total = 0;
    for (NSDictionary *productInfo in _selectedProducts) {
        _total += [productInfo[@"total"] floatValue];
    }
    _totalLabel.text = [NSString stringWithFormat:NSLocalizedStringByKey(@"selectedProductsTotalPrice"), [FasTFormatter stringForPrice:_total]];
}

- (void)updateSelectedProductsTable
{
    [[self selectedProductsTable] reloadData];
}

- (void)updateSelectedProductsTableAndTotal
{
    [self updateTotal];
    [self updateSelectedProductsTable];
}

- (IBAction)openCashDrawer
{
    [[FasTCashDrawer defaultCashDrawer] open];
}

- (void)finishPurchase
{
//    NSDictionary *newOrder = nil;
//    NSMutableArray *items = [NSMutableArray array];
//    for (NSDictionary *productInfo in _selectedProducts) {
//        if ([productInfo[@"type"] isEqualToString:@"order"] && !productInfo[@"id"]) {
//            NSMutableDictionary *tickets = [NSMutableDictionary dictionary];
//            for (NSDictionary *type in [[orderController order] tickets]) {
//                tickets[[type[@"type"] typeId]] = type[@"number"];
//            }
//            newOrder = @{@"date": [[[orderController order] date] dateId], @"tickets": tickets};
//        } else {
//            NSDictionary *itemInfo = @{ @"id": productInfo[@"id"], @"number": _selectedProducts[productInfo], @"type": productInfo[@"type"] };
//            [items addObject:itemInfo];
//        }
//    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
//    [[FasTApi defaultApi] finishPurchaseWithItems:items newOrder:newOrder total:total callback:^(NSDictionary *response) {
//        [hud hide:YES];
//        if (response && [response[@"ok"] boolValue]) {
//            if (response[@"new_order"]) {
//                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:response[@"new_order"] event:[[FasTApi defaultApi] event]] autorelease];
//                [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:order];
//            }
//            [self finishedPurchase];
//        } else {
//            [self showAlertWithTitle:NSLocalizedStringByKey(@"finishedPurchaseErrorTitle") details:NSLocalizedStringByKey(@"finishedPurchaseErrorDetails")];
//        }
//    }];
}

- (void)finishedPurchase
{
    for (FasTOrder *order in _ticketsToPay) {
        [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:order];
    }
    [self showAlertWithTitle:NSLocalizedStringByKey(@"finishedPurchaseTitle") details:[NSString stringWithFormat:NSLocalizedStringByKey(@"finishedPurchaseDetails"), [FasTFormatter stringForPrice:_total]]];
    [self clearPurchase:nil];
    [self openCashDrawer];
}

- (IBAction)clearPurchase:(id)sender
{
    [_selectedProducts removeAllObjects];
    [self updateSelectedProductsTableAndTotal];
    [_ticketsToPay removeAllObjects];
}

- (void)showAlertWithTitle:(NSString *)title details:(NSString *)details
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:details delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
    [alert show];
}

- (void)receivedTicketsToPay:(NSNotification *)note
{
    NSArray *tickets = [note userInfo][@"tickets"];
    for (FasTTicket *ticket in tickets) {
        if (![_ticketsToPay containsObject:ticket]) {
            [_ticketsToPay addObject:ticket];
            NSDictionary *product = @{ @"type": @"ticket", @"number": @(1), @"total": @(ticket.price), @"product": @{ @"name": ticket.type.name, @"price": @(ticket.price) } };
            [_selectedProducts addObject:product];
        }
    }
    
    [self updateSelectedProductsTableAndTotal];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTSwitchToPurchaseController" object:self];
}

#pragma mark table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _availableProductsTable) {
        return _availableProducts.count + 1;
    } else {
        return _selectedProducts.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == _availableProductsTable) {
        return @"Verfügbare Artikel";
    } else {
        return @"Warenkorb";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (tableView == _availableProductsTable) {
        BOOL firstRow = indexPath.row == 0;
        cell = [tableView dequeueReusableCellWithIdentifier:firstRow ? @"FasTPurchaseProductTicketsCell" : @"FasTPurchaseProductCell"];
        if (firstRow) {
            cell.detailTextLabel.text = [NSString stringWithFormat:cell.detailTextLabel.text, 5];
        } else {
            NSDictionary *productInfo = [self productInfoForIndexPath:indexPath];
            cell.textLabel.text = productInfo[@"name"];
            cell.detailTextLabel.text = [FasTFormatter stringForPrice:[productInfo[@"price"] floatValue]];
        }
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"FasTPurchaseSelectedProductCell"];
        NSDictionary *productInfo = _selectedProducts[indexPath.row];
        for (NSInteger i = 1; i <= 3; i++) {
            UILabel *label = (UILabel *)[cell viewWithTag:i];
            switch (i) {
                case 1:
                    label.text = productInfo[@"product"][@"name"];
                    break;
                case 2: {
                    NSString *price = [FasTFormatter stringForPrice:[productInfo[@"product"][@"price"] floatValue]];
                    label.text = [NSString stringWithFormat:@"%@ x %@", productInfo[@"number"], price];
                    break;
                }
                default:
                    label.text = [FasTFormatter stringForPrice:[productInfo[@"total"] floatValue]];
                    break;
            }
        }
    }
    
    return cell;
}

#pragma mark table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView cellForRowAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"FasTPurchaseProductCell"]) {
        NSDictionary *productInfo = [self productInfoForIndexPath:indexPath];
        NSMutableDictionary *selectedProduct = nil;
        for (NSMutableDictionary *product in _selectedProducts) {
            if ([product[@"product"][@"id"] isEqualToString:productInfo[@"id"]]) {
                selectedProduct = product;
                break;
            }
        }
        if (!selectedProduct) {
            selectedProduct = [NSMutableDictionary dictionaryWithDictionary:@{@"type": @"product", @"product": productInfo, @"number": @(1), @"total": productInfo[@"price"]}];
            [_selectedProducts addObject:selectedProduct];
        } else {
            NSInteger number = [selectedProduct[@"number"] integerValue] + 1;
            selectedProduct[@"number"] = @(number);
            selectedProduct[@"total"] = @(number * [productInfo[@"price"] floatValue]);
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateSelectedProductsTableAndTotal];
}

#pragma mark order controller delegate

- (void)dismissorderViewController:(FasTOrderViewController *)ovc finished:(BOOL)finished
{
    [ovc dismissViewControllerAnimated:YES completion:NULL];
    if (!finished) return;
    
    FasTOrder *order = [ovc order];
    NSDictionary *product = @{@"type": @"order", @"name": @"Tickets", @"product": order, @"price": @([order total])};
    [_selectedProducts addObject:product];
    
    [self updateSelectedProductsTableAndTotal];
}

- (void)orderInViewControllerExpired:(FasTOrderViewController *)ovc
{
    for (NSDictionary *productInfo in _selectedProducts) {
        if ([productInfo[@"type"] isEqualToString:@"order"] && !productInfo[@"id"]) {
            [_selectedProducts removeObject:productInfo];
            [self updateSelectedProductsTableAndTotal];
            return;
        }
    }
}

@end
