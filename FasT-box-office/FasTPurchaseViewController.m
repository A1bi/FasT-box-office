//
//  FasTPurchaseViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTPurchaseViewController.h"
#import "FasTMainViewController.h"
#import "FasTProduct.h"
#import "FasTCartProductItem.h"
#import "FasTCartTicketItem.h"
#import "FasTFormatter.h"
#import "FasTApi.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTEventDate.h"
#import "FasTTicketPrinter.h"
#import "FasTReceiptPrinter.h"
#import "MBProgressHUD.h"

@interface FasTPurchaseViewController ()

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath;
- (void)updateTotal;
- (void)decreaseCartItemAtIndexPath:(NSIndexPath *)indexPath remove:(BOOL)completely;
- (void)addCartItem:(FasTCartItem *)cartItem;
- (void)removeCartItemIndexPathsFromTable:(NSArray *)indexPaths;
- (void)reloadCartItemIndexPathsInTable:(NSArray *)indexPaths;
- (void)finishedPurchase;
- (void)receivedTicketsToPay:(NSNotification *)note;

@end

@implementation FasTPurchaseViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSArray *products = @[
                      @[@"1", @"Programmheft", @(1)],
                      @[@"2", @"Regenponcho", @(1)],
                      @[@"3", @"Tasse", @(5)],
                      @[@"4", @"T-Shirt", @(19.95)],
                      @[@"5", @"Kappe", @(9)]
                      ];
        NSMutableArray *tmpProducts = [NSMutableArray array];
        for (NSArray *product in products) {
            [tmpProducts addObject:[[[FasTProduct alloc] initWithId:product[0] name:product[1] price:[product[2] floatValue]] autorelease]];
        }
        _availableProducts = [[NSArray alloc] initWithArray:tmpProducts];
        
        _cartItems = [[NSMutableArray alloc] init];
        _ticketsToPay = [[NSMutableArray alloc] init];
        
//        orderController = [[FasTOrderViewController alloc] init];
//        [orderController setDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTicketsToPay:) name:@"FasTPurchaseControllerAddTicketsToPay" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_availableProducts release];
    [_cartItems release];
    [_ticketsToPay release];
    [_cartItemsTable release];
    [_totalLabel release];
    [_availableProductsTable release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateTotal];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    return (![identifier isEqualToString:@"FasTPurchasePaymentSegue"] || _cartItems.count > 0);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FasTPurchasePaymentSegue"]) {
        FasTPurchasePaymentViewController *payment = segue.destinationViewController;
        payment.cartItems = _cartItems;
        payment.delegate = self;
    }
}

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath
{
    return _availableProducts[indexPath.row - 1];
}

- (void)updateTotal
{
    NSNumber *total = [_cartItems valueForKeyPath:@"@sum.total"];
    _totalLabel.text = [NSString stringWithFormat:NSLocalizedStringByKey(@"selectedProductsTotalPrice"), [FasTFormatter stringForPrice:total.floatValue]];
}

- (void)decreaseCartItemAtIndexPath:(NSIndexPath *)indexPath remove:(BOOL)remove
{
    FasTCartItem *cartItem = _cartItems[indexPath.row];
    [cartItem decreaseQuantity];
    if (remove || cartItem.quantity < 1) {
        if ([cartItem isKindOfClass:[FasTCartTicketItem class]]) {
            [_ticketsToPay removeObject:((FasTCartTicketItem *)cartItem).ticket];
        }
        [_cartItems removeObject:cartItem];
        [self removeCartItemIndexPathsFromTable:@[indexPath]];
    } else {
        [self reloadCartItemIndexPathsInTable:@[indexPath]];
    }
}

- (void)addCartItem:(FasTCartItem *)cartItem
{
    [_cartItems addObject:cartItem];
    [_cartItemsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_cartItems.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)removeCartItemIndexPathsFromTable:(NSArray *)indexPaths
{
    [_cartItemsTable deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reloadCartItemIndexPathsInTable:(NSArray *)indexPaths
{
    [_cartItemsTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)openCashDrawer
{
    [[FasTReceiptPrinter sharedPrinter] openCashDrawer];
}

- (void)finishedPurchase
{
    [self clearPurchase:nil];
}

- (IBAction)clearPurchase:(id)sender
{
    if (_cartItems.count < 1) return;
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0, c = _cartItems.count; i < c; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [_ticketsToPay removeAllObjects];
    [_cartItems removeAllObjects];
    [self removeCartItemIndexPathsFromTable:indexPaths];
    [self updateTotal];
}

- (void)receivedTicketsToPay:(NSNotification *)note
{
    NSArray *tickets = [note userInfo][@"tickets"];
    for (FasTTicket *ticket in tickets) {
        if (![_ticketsToPay containsObject:ticket]) {
            [_ticketsToPay addObject:ticket];
            FasTCartTicketItem *cartItem = [[[FasTCartTicketItem alloc] initWithTicket:ticket] autorelease];
            [self addCartItem:cartItem];
        }
    }
    
    [self updateTotal];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTSwitchToPurchaseController" object:self];
}

- (void)dismissedPurchasePaymentViewController
{
    [self finishedPurchase];
}

#pragma mark table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _availableProductsTable) {
        return _availableProducts.count + 1;
    } else {
        return _cartItems.count;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView == _cartItemsTable;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (tableView == _availableProductsTable) {
        BOOL firstRow = indexPath.row == 0;
        cell = [tableView dequeueReusableCellWithIdentifier:firstRow ? @"FasTPurchaseProductTicketsCell" : @"FasTPurchaseProductCell"];
        if (firstRow) {
            cell.detailTextLabel.text = [NSString stringWithFormat:cell.detailTextLabel.text, 0];
        } else {
            FasTProduct *product = [self productForIndexPath:indexPath];
            cell.textLabel.text = product.name;
            cell.detailTextLabel.text = [FasTFormatter stringForPrice:product.price];
        }
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"FasTPurchaseSelectedProductCell"];
        FasTCartItem *cartItem = _cartItems[indexPath.row];
        for (NSInteger i = 1; i <= 3; i++) {
            UILabel *label = (UILabel *)[cell viewWithTag:i];
            switch (i) {
                case 1:
                    label.text = cartItem.name;
                    break;
                case 2: {
                    NSString *price = [FasTFormatter stringForPrice:cartItem.price];
                    label.text = [NSString stringWithFormat:@"%ld x %@", (long)cartItem.quantity, price];
                    break;
                }
                default:
                    label.text = [FasTFormatter stringForPrice:cartItem.total];
                    break;
            }
        }
    }
    
    return cell;
}

#pragma mark table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [tableView cellForRowAtIndexPath:indexPath].reuseIdentifier;
    if ([identifier isEqualToString:@"FasTPurchaseProductCell"]) {
        FasTProduct *product = [self productForIndexPath:indexPath];
        FasTCartItem *cartItem = product.cartItem;
        if (!cartItem) {
            cartItem = [[[FasTCartProductItem alloc] initWithProduct:product] autorelease];
            [self addCartItem:cartItem];
        } else {
            [cartItem increaseQuantity];
            NSIndexPath *cartItemPath = [NSIndexPath indexPathForRow:[_cartItems indexOfObject:cartItem] inSection:0];
            [self reloadCartItemIndexPathsInTable:@[cartItemPath]];
        }
    
    } else if ([identifier isEqualToString:@"FasTPurchaseProductTicketsCell"]) {
        
    
    } else {
        [self decreaseCartItemAtIndexPath:indexPath remove:NO];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateTotal];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self decreaseCartItemAtIndexPath:indexPath remove:YES];
        [self updateTotal];
    }
}

#pragma mark order controller delegate

- (void)dismissorderViewController:(FasTOrderViewController *)ovc finished:(BOOL)finished
{
//    [ovc dismissViewControllerAnimated:YES completion:NULL];
//    if (!finished) return;
//    
//    FasTOrder *order = [ovc order];
//    NSDictionary *product = @{@"type": @"order", @"name": @"Tickets", @"product": order, @"price": @([order total])};
//    [_cartItems addObject:product];
//    
//    [self updateSelectedProductsTableAndTotal];
}

- (void)orderInViewControllerExpired:(FasTOrderViewController *)ovc
{
//    for (NSDictionary *productInfo in _cartItems) {
//        if ([productInfo[@"type"] isEqualToString:@"order"] && !productInfo[@"id"]) {
//            [_cartItems removeObject:productInfo];
//            [self updateSelectedProductsTableAndTotal];
//            return;
//        }
//    }
}

@end
