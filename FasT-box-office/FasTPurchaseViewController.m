//
//  FasTPurchaseViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTPurchaseViewController.h"
#import "FasTMainViewController.h"
#import "FasTOrderViewController.h"
#import "FasTProduct.h"
#import "FasTCartProductItem.h"
#import "FasTCartTicketItem.h"
#import "FasTCartRefundItem.h"
#import "FasTFormatter.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTSeat.h"
#import "FasTTicketPrinter.h"
#import "FasTReceiptPrinter.h"
#import "MBProgressHUD.h"

@interface FasTPurchaseViewController ()
{
    NSArray *_availableProducts;
    NSMutableArray *_cartItems;
    NSMutableArray *_ticketsToPay;
    NSMutableArray *_placedOrders;
    FasTEventDate *_todaysDate;
    NSInteger _numberOfAvailableTickets;
}

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath;
- (void)updateTotal;
- (void)decreaseCartItemAtIndexPath:(NSIndexPath *)indexPath remove:(BOOL)completely;
- (void)addCartItem:(FasTCartItem *)cartItem;
- (void)removeCartItemIndexPathsFromTable:(NSArray *)indexPaths;
- (void)reloadCartItemIndexPathsInTable:(NSArray *)indexPaths;
- (void)clearCart;
- (void)addTicketsToPay:(NSArray *)tickets;
- (void)receivedTicketsToPay:(NSNotification *)note;
- (void)receivedRefund:(NSNotification *)note;
- (void)updateNumberOfAvailableTickets;
- (void)switchToSelf;

@end

@implementation FasTPurchaseViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[FasTApi defaultApi] getResource:@"api/box_office" withAction:@"products" callback:^(NSDictionary *response) {
            NSMutableArray *tmpProducts = [NSMutableArray array];
            for (NSDictionary *productInfo in response[@"products"]) {
                FasTProduct *product = [[[FasTProduct alloc] initWithId:productInfo[@"id"] name:productInfo[@"name"] price:((NSNumber *)productInfo[@"price"]).floatValue] autorelease];
                [tmpProducts addObject:product];
            }
            _availableProducts = [[NSArray alloc] initWithArray:tmpProducts];
            [self.availableProductsTable reloadData];
        }];
        
        _cartItems = [[NSMutableArray alloc] init];
        _ticketsToPay = [[NSMutableArray alloc] init];
        _placedOrders = [[NSMutableArray alloc] init];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(receivedTicketsToPay:) name:@"FasTPurchaseControllerAddTicketsToPay" object:nil];
        [center addObserver:self selector:@selector(receivedRefund:) name:@"FasTPurchaseControllerAddRefund" object:nil];
        [center addObserver:self selector:@selector(updateNumberOfAvailableTickets) name:FasTApiUpdatedSeatsNotification object:nil];
        [center addObserverForName:FasTApiIsReadyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            for (FasTEventDate *date in [FasTApi defaultApi].event.dates) {
                if ([date.date isToday]) {
                    _todaysDate = date;
                    break;
                }
            }
            if (!_todaysDate) {
                _todaysDate = [FasTApi defaultApi].event.dates.lastObject;
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_availableProducts release];
    [_cartItems release];
    [_ticketsToPay release];
    [_placedOrders release];
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
    } else if ([segue.identifier isEqualToString:@"FasTOrderSegue"]) {
        ((FasTOrderViewController *)segue.destinationViewController).delegate = self;
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
    
    if ([cartItem isKindOfClass:[FasTCartTicketItem class]]) {
        FasTTicket *ticket = ((FasTCartTicketItem *)cartItem).ticket;
        for (FasTOrder *order in _placedOrders) {
            if ([order.tickets indexOfObject:ticket] != NSNotFound) {
                return;
            }
        }
    }
    
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

- (void)cancelPurchase
{
    for (FasTOrder *order in _placedOrders) {
        [[FasTApi defaultApi] cancelBoxOfficeOrder:order];
    }
    
    [self clearCart];
}

- (void)clearCart
{
    if (_cartItems.count < 1) return;
    
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0, c = _cartItems.count; i < c; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    [_ticketsToPay removeAllObjects];
    [_placedOrders removeAllObjects];
    [_cartItems removeAllObjects];
    [self removeCartItemIndexPathsFromTable:indexPaths];
    [self updateTotal];
}

- (void)addTicketsToPay:(NSArray *)tickets
{
    for (FasTTicket *ticket in tickets) {
        if (![_ticketsToPay containsObject:ticket]) {
            [_ticketsToPay addObject:ticket];
            FasTCartTicketItem *cartItem = [[[FasTCartTicketItem alloc] initWithTicket:ticket] autorelease];
            [self addCartItem:cartItem];
        }
    }
    
    [self updateTotal];
}

- (void)receivedTicketsToPay:(NSNotification *)note
{
    NSArray *tickets = [note userInfo][@"tickets"];
    [self addTicketsToPay:tickets];
    
    [self switchToSelf];
}

- (void)receivedRefund:(NSNotification *)note
{
    float amount = ((NSNumber *)note.userInfo[@"amount"]).floatValue;
    FasTCartRefundItem *refund = [[[FasTCartRefundItem alloc] initWithAmount:amount order:note.userInfo[@"order"]] autorelease];
    [self addCartItem:refund];
    [self updateTotal];
    [self switchToSelf];
}

- (void)dismissedPurchasePaymentViewControllerFinished:(BOOL)finished
{
    if (finished) {
        [self clearCart];
    }
}

- (void)paymentFinishedInPaymentViewController
{
    [[FasTTicketPrinter sharedPrinter] printTickets:_ticketsToPay];
}

- (void)updateNumberOfAvailableTickets
{
    _numberOfAvailableTickets = 0;
    NSArray *seats = [[FasTApi defaultApi].event.seats[_todaysDate.dateId] allValues];
    for (FasTSeat *seat in seats) {
        if (!seat.taken) _numberOfAvailableTickets++;
    }
    
    [self.availableProductsTable reloadData];
}

- (void)switchToSelf
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTSwitchToPurchaseController" object:self];
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
            cell.detailTextLabel.text = [NSString stringWithFormat:@"für heute noch %li Tickets verfügbar", (long)_numberOfAvailableTickets];
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

- (void)didPlaceOrder:(FasTOrder *)order
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [[FasTApi defaultApi] placeOrder:order callback:^(FasTOrder *order) {
        [[FasTApi defaultApi] resetSeating];
        
        [self addTicketsToPay:order.tickets];
        [_placedOrders addObject:order];
        
        [hud hide:YES];
    }];
}

@end
