//
//  FasTPurchaseViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTPurchaseViewController.h"
#import "FasTCashDrawer.h"
#import "FasTFormatter.h"
#import "FasTApi.h"
#import "FasTOrder.h"
#import "FasTTicketType.h"
#import "FasTEventDate.h"
#import "FasTTicketPrinter.h"
#import "MBProgressHUD.h"

static NSString *cellId = @"selectedProductCell";

@interface FasTPurchaseViewController ()

- (void)selectedProduct:(UIButton *)btn;
- (void)updateTotal;
- (void)finishedPurchase;
- (void)showAlertWithTitle:(NSString *)title details:(NSString *)details;

@end

@implementation FasTPurchaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        products = [@[
                     @{@"type": @"product", @"id": @"1", @"name": @"Programmheft", @"price": @(1)},
                     @{@"type": @"product", @"id": @"2", @"name": @"Regenponcho", @"price": @(1)}
                     ] retain];
        selectedProducts = [[NSMutableDictionary dictionary] retain];
        
        orderController = [[FasTOrderViewController alloc] init];
        [orderController setDelegate:self];
        
        [self setTitle:NSLocalizedStringByKey(@"purchaseControllerTabTitle")];
        [[self navigationItem] setTitle:NSLocalizedStringByKey(@"purchaseControllerNavigationTitle")];
    }
    return self;
}

- (void)dealloc
{
    [products release];
    [selectedProducts release];
    [_selectedProductsTable release];
    [_totalLabel release];
    [_buyTicketsBtn release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [[self selectedProductsTable] setDataSource:self];
    [[self selectedProductsTable] registerNib:[UINib nibWithNibName:@"FasTSelectedProductTableViewCell" bundle:nil] forCellReuseIdentifier:cellId];
    
    CGRect frame = [[self buyTicketsBtn] frame];
    NSInteger i = 0;
    for (NSDictionary *productInfo in products) {
        frame.origin.y += frame.size.height + 10;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [btn setFrame:frame];
        [btn setTag:100 + i];
        [[btn titleLabel] setFont:[UIFont boldSystemFontOfSize:18]];
        [btn setTitle:[NSString stringWithFormat:@"%@ %@", productInfo[@"name"], [FasTFormatter stringForPrice:[productInfo[@"price"] floatValue]]] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(selectedProduct:) forControlEvents:UIControlEventTouchUpInside];
        [[self view] addSubview:btn];
        i++;
    }
    
    [self updateTotal];
}

- (void)selectedProduct:(UIButton *)btn
{
    NSDictionary *productInfo = products[[btn tag] - 100];
    NSNumber *number = selectedProducts[productInfo];
    if (!number) {
        number = @(1);
    } else {
        number = @([number intValue]+1);
    }
    selectedProducts[productInfo] = number;
    
    if (number) [[self selectedProductsTable] reloadData];
    [self updateTotal];
}

- (void)updateTotal
{
    total = 0;
    for (NSDictionary *productInfo in selectedProducts) {
        total += [productInfo[@"price"] floatValue] * ([productInfo[@"type"] isEqualToString:@"order"] ? 1 : [selectedProducts[productInfo] intValue]);
    }
    [[self totalLabel] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"selectedProductsTotalPrice"), [FasTFormatter stringForPrice:total]]];
}

- (IBAction)openCashDrawer
{
    [[FasTCashDrawer defaultCashDrawer] open];
}

- (IBAction)finishPurchase:(id)sender
{
    NSDictionary *newOrder = nil;
    NSMutableArray *items = [NSMutableArray array];
    for (NSDictionary *productInfo in selectedProducts) {
        if ([productInfo[@"type"] isEqualToString:@"order"] && !productInfo[@"id"]) {
            NSMutableDictionary *tickets = [NSMutableDictionary dictionary];
            for (NSDictionary *type in [[orderController order] tickets]) {
                tickets[[type[@"type"] typeId]] = type[@"number"];
            }
            newOrder = @{@"date": [[[orderController order] date] dateId], @"tickets": tickets};
        } else {
            NSDictionary *itemInfo = @{ @"id": productInfo[@"id"], @"number": selectedProducts[productInfo], @"type": @"product" };
            [items addObject:itemInfo];
        }
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
    [[FasTApi defaultApi] finishPurchaseWithItems:items newOrder:newOrder total:total callback:^(NSDictionary *response) {
        [hud hide:YES];
        if (response && [response[@"ok"] boolValue]) {
            if (response[@"new_order"]) {
                FasTOrder *order = [[[FasTOrder alloc] initWithInfo:response[@"new_order"] event:[[FasTApi defaultApi] event]] autorelease];
                [[FasTTicketPrinter sharedPrinter] printTicketsForOrder:order];
            }
            [self finishedPurchase];
        } else {
            [self showAlertWithTitle:NSLocalizedStringByKey(@"finishedPurchaseErrorTitle") details:NSLocalizedStringByKey(@"finishedPurchaseErrorDetails")];
        }
    }];
}

- (void)finishedPurchase
{
    [self showAlertWithTitle:NSLocalizedStringByKey(@"finishedPurchaseTitle") details:[NSString stringWithFormat:NSLocalizedStringByKey(@"finishedPurchaseDetails"), [FasTFormatter stringForPrice:total]]];
    [self clearPurchase:nil];
    [self openCashDrawer];
}

- (IBAction)clearPurchase:(id)sender
{
    [selectedProducts removeAllObjects];
    [self updateTotal];
    [[self selectedProductsTable] reloadData];
    [[self buyTicketsBtn] setHidden:NO];
    [orderController resetOrder];
}

- (IBAction)showOrderController:(id)sender
{
    [self presentViewController:orderController animated:YES completion:NULL];
}

- (void)showAlertWithTitle:(NSString *)title details:(NSString *)details
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:details delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
    [alert show];
}

#pragma mark table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[selectedProducts allKeys] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedStringByKey(@"selectedProducts");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FasTSelectedProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    NSDictionary *productInfo = [selectedProducts allKeys][[indexPath row]];
    [[cell nameLabel] setText:productInfo[@"name"]];
    BOOL orderStyle = NO;
    if ([productInfo[@"type"] isEqualToString:@"order"]) {
        orderStyle = YES;
    } else {
        [cell setDelegate:self];
    }
    [cell enableOrderStyle:orderStyle];
    [cell setProductInfo:productInfo];
    [cell setNumber:[selectedProducts[productInfo] intValue]];
    return cell;
}

#pragma mark selected product cell delegate

- (void)selectedProductCellChangedNumber:(FasTSelectedProductTableViewCell *)cell
{
    if ([cell number] <= 0) {
        [selectedProducts removeObjectForKey:[cell productInfo]];
        [[self selectedProductsTable] reloadData];
    } else {
        selectedProducts[[cell productInfo]] = @([cell number]);
    }
    [self updateTotal];
}

#pragma mark order controller delegate

- (void)dismissorderViewController:(FasTOrderViewController *)ovc finished:(BOOL)finished
{
    [ovc dismissViewControllerAnimated:YES completion:NULL];
    [[self buyTicketsBtn] setHidden:finished];
    FasTOrder *order = [ovc order];
    selectedProducts[@{@"type": @"order", @"name": @"Tickets", @"price": @([order total])}] = @([order numberOfTickets]);
    
    [[self selectedProductsTable] reloadData];
    [self updateTotal];
}

@end
