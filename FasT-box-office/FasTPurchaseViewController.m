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

static NSString *cellId = @"selectedProductCell";

@interface FasTPurchaseViewController ()

- (void)selectedProduct:(UIButton *)btn;
- (void)updateTotal;

@end

@implementation FasTPurchaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        products = [@[
                     @{@"id": @"1", @"name": @"Programmheft", @"price": @(1)},
                     @{@"id": @"2", @"name": @"Regenponcho", @"price": @(1)}
                     ] retain];
        selectedProducts = [[NSMutableDictionary dictionary] retain];
        
        [self setTitle:NSLocalizedStringByKey(@"purchaseControllerTabTitle")];
        [[self navigationItem] setTitle:NSLocalizedStringByKey(@"purchaseControllerNavigationTitle")];
    }
    return self;
}

- (void)dealloc
{
    [_buyTicketsBtn release];
    [products release];
    [selectedProducts release];
    [_selectedProductsTable release];
    [_totalLabel release];
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
    float total = 0;
    for (NSDictionary *productInfo in selectedProducts) {
        total += [productInfo[@"price"] floatValue] * [selectedProducts[productInfo] intValue];
    }
    [[self totalLabel] setText:[NSString stringWithFormat:NSLocalizedStringByKey(@"selectedProductsTotalPrice"), [FasTFormatter stringForPrice:total]]];
}

- (IBAction)openCashDrawer
{
    [[FasTCashDrawer defaultCashDrawer] open];
}

- (IBAction)finishPurchase:(id)sender
{
    [self openCashDrawer];
}

- (IBAction)clearPurchase:(id)sender
{
    [selectedProducts removeAllObjects];
    [[self selectedProductsTable] reloadData];
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
    [cell setProductInfo:productInfo];
    [cell setNumber:[selectedProducts[productInfo] intValue]];
    [cell setDelegate:self];
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

@end
