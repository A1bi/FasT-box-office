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
#import "MBProgressHUD.h"

@interface FasTPurchaseViewController ()

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath;
- (void)updateSelectedProductsTableAndTotal;
- (void)updateTotal;
- (void)updateSelectedProductsTable;
- (void)decreaseSelectedProductAtIndexPath:(NSIndexPath *)indexPath remove:(BOOL)completely;
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
        NSArray *products = @[
                      @[@"1", @"Programmheft", @(1)],
                      @[@"2", @"Regenponcho", @(1)],
                      @[@"3", @"Tasse", @(5)],
                      @[@"4", @"T-Shirt", @(19.95)],
                      @[@"5", @"Kappe", @(9)]
                      ];
        NSMutableArray *tmpProducts = [NSMutableArray array];
        for (NSArray *product in products) {
            [tmpProducts addObject:[[[FasTProduct alloc] initWithName:product[1] price:[product[2] floatValue]] autorelease]];
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
    return (![identifier isEqualToString:@"FasTPurchasePaymentSegue"] || _total > 0);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FasTPurchasePaymentSegue"]) {
        FasTPurchasePaymentViewController *payment = segue.destinationViewController;
        payment.total = _total;
        payment.delegate = self;
        
        if (_ticketsToPay.count > 0) {
            [[FasTApi defaultApi] markTickets:_ticketsToPay paid:YES pickedUp:YES];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tickets drucken?" message:@"Möchten Sie die zu bezahlenden Tickets ausdrucken?" delegate:self cancelButtonTitle:@"Nein" otherButtonTitles:@"Ja", nil];
            [alert show];
        }
        //[self finishedPurchase];
    }
}

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath
{
    return _availableProducts[indexPath.row - 1];
}

- (void)updateTotal
{
    _total = 0;
    for (FasTCartItem *cartItem in _cartItems) {
        _total += cartItem.total;
    }
    _totalLabel.text = [NSString stringWithFormat:NSLocalizedStringByKey(@"selectedProductsTotalPrice"), [FasTFormatter stringForPrice:_total]];
}

- (void)updateSelectedProductsTable
{
    [self.cartItemsTable reloadData];
}

- (void)updateSelectedProductsTableAndTotal
{
    [self updateTotal];
    [self updateSelectedProductsTable];
}

- (void)decreaseSelectedProductAtIndexPath:(NSIndexPath *)indexPath remove:(BOOL)completely
{
    FasTCartItem *cartItem = _cartItems[indexPath.row];
    [cartItem decreaseQuantity];
    if (completely || cartItem.quantity < 1) {
        if ([cartItem isKindOfClass:[FasTCartTicketItem class]]) {
            [_ticketsToPay removeObject:((FasTCartTicketItem *)cartItem).ticket];
        }
        [_cartItems removeObject:cartItem];
    }
}

- (IBAction)openCashDrawer
{
    //[[FasTCashDrawer defaultCashDrawer] open];
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
    [self clearPurchase:nil];
}

- (IBAction)clearPurchase:(id)sender
{
    [_cartItems removeAllObjects];
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
            FasTCartTicketItem *cartItem = [[[FasTCartTicketItem alloc] initWithTicket:ticket] autorelease];
            [_cartItems addObject:cartItem];
        }
    }
    
    [self updateSelectedProductsTableAndTotal];
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
            [_cartItems addObject:cartItem];
        } else {
            [cartItem increaseQuantity];
        }
    
    } else if ([identifier isEqualToString:@"FasTPurchaseProductTicketsCell"]) {
        
    
    } else {
        [self decreaseSelectedProductAtIndexPath:indexPath remove:NO];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateSelectedProductsTableAndTotal];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self decreaseSelectedProductAtIndexPath:indexPath remove:YES];
        [self updateSelectedProductsTableAndTotal];
    }
}

#pragma mark alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[FasTTicketPrinter sharedPrinter] printTickets:_ticketsToPay];
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
