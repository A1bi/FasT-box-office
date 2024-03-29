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
#import "FasTCartOrderPaymentItem.h"
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
@import MBProgressHUD;

@interface FasTPurchaseViewController ()
{
    NSArray *_availableProducts;
    NSMutableArray *_cartItems;
    NSMutableArray *_ticketsInCart;
    NSMutableArray *_ticketsToPrint;
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
- (void)receivedOrderPayment:(NSNotification *)note;
- (void)printTicketsInCart;
- (void)updateNumberOfAvailableTickets;
- (void)switchToSelf;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end

@implementation FasTPurchaseViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _cartItems = [[NSMutableArray alloc] init];
        _ticketsInCart = [[NSMutableArray alloc] init];
        _ticketsToPrint = [[NSMutableArray alloc] init];
        _placedOrders = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_availableProducts release];
    [_cartItems release];
    [_ticketsInCart release];
    [_ticketsToPrint release];
    [_placedOrders release];
    [_cartItemsTable release];
    [_totalLabel release];
    [_availableProductsTable release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(receivedTicketsToPay:) name:@"FasTPurchaseControllerAddTicketsToPay" object:nil];
    [center addObserver:self selector:@selector(receivedOrderPayment:) name:@"FasTPurchaseControllerAddOrderPayment" object:nil];
    
    [[FasTApi defaultApi] getResource:@"api/ticketing/box_office/products" withAction:nil callback:^(NSDictionary *response) {
        NSMutableArray *tmpProducts = [NSMutableArray array];
        for (NSDictionary *productInfo in response[@"products"]) {
            FasTProduct *product = [[[FasTProduct alloc] initWithId:productInfo[@"id"] name:productInfo[@"name"] price:((NSNumber *)productInfo[@"price"]).floatValue] autorelease];
            [tmpProducts addObject:product];
        }
        [_availableProducts release];
        _availableProducts = [[NSArray alloc] initWithArray:tmpProducts];
        [self.availableProductsTable reloadData];
    }];
    
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
        
        if (@available(iOS 13.0, *)) {
            [payment setModalInPresentation:YES];
        }

        [self printTicketsInCart];

    } else if ([segue.identifier isEqualToString:@"FasTOrderSegue"]) {
        ((FasTOrderViewController *)segue.destinationViewController).delegate = self;
    }
}

- (FasTProduct *)productForIndexPath:(NSIndexPath *)indexPath
{
    if (!_availableProducts) return 0;
    
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
            [_ticketsInCart removeObject:((FasTCartTicketItem *)cartItem).ticket];
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
    [_ticketsInCart removeAllObjects];
    [_ticketsToPrint removeAllObjects];
    [_placedOrders removeAllObjects];
    [_cartItems removeAllObjects];
    [self removeCartItemIndexPathsFromTable:indexPaths];
    [self updateTotal];
}

- (void)addTicketsToPay:(NSArray *)tickets
{
    for (FasTTicket *ticket in tickets) {
        if (![_ticketsInCart containsObject:ticket]) {
            [_ticketsInCart addObject:ticket];
            FasTCartTicketItem *cartItem = [[[FasTCartTicketItem alloc] initWithTicket:ticket] autorelease];
            [self addCartItem:cartItem];
        }

        if (![_ticketsToPrint containsObject:ticket]) {
            [_ticketsToPrint addObject:ticket];
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

- (void)receivedOrderPayment:(NSNotification *)note
{
    float amount = ((NSNumber *)note.userInfo[@"amount"]).floatValue;
    FasTCartOrderPaymentItem *payment = [[[FasTCartOrderPaymentItem alloc] initWithAmount:amount order:note.userInfo[@"order"]] autorelease];
    [self addCartItem:payment];
    [self updateTotal];
    [self switchToSelf];
}

- (void)printTicketsInCart
{
    [[FasTTicketPrinter sharedPrinter] printTickets:_ticketsToPrint];
    [_ticketsToPrint removeAllObjects];
}

- (void)paymentFinishedInPaymentViewController
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTPurchaseFinished" object:self];
    [self clearCart];
}

- (void)updateNumberOfAvailableTickets
{
    // TODO: fix
    _numberOfAvailableTickets = 0;
    
    [self.availableProductsTable reloadData];
}

- (void)switchToSelf
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FasTSwitchToPurchaseController" object:self];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmationAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL];
    [confirmation addAction:confirmationAction];

    [self presentViewController:confirmation animated:YES completion:NULL];
}

#pragma mark table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == _availableProductsTable) {
        return (_availableProducts ? _availableProducts.count : 0) + 1;
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
            if (_todaysDate && _todaysDate.event.hasSeatingPlan) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"für heute noch %li Tickets verfügbar", (long)_numberOfAvailableTickets];
            } else {
                cell.detailTextLabel.text = nil;
            }
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
        if (order) {
            [[FasTApi defaultApi] resetSeating];
            [self addTicketsToPay:order.tickets];
            [_placedOrders addObject:order];

        } else {
            [self showAlertWithTitle:@"Fehler bei der Buchung" message:@"Leider ist beim Buchen der Tickets etwas schiefgelaufen."];
        }
        
        [hud hideAnimated:YES];
    }];
}

@end
