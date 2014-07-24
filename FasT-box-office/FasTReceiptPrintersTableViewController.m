//
//  FasTCashDrawerTableViewController.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 15.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTReceiptPrintersTableViewController.h"
#import "ESCPrinter.h"

@interface FasTReceiptPrintersTableViewController ()

@end

@implementation FasTReceiptPrintersTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _foundPrinters = [[NSMutableArray alloc] init];
        _currentHostName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"FasTReceiptPrinterHostname"] retain];
        
        _browser = [[NSNetServiceBrowser alloc] init];
        [_browser setDelegate:self];
        [_browser searchForServicesOfType:@"_esc_printer._tcp." inDomain:@""];
    }
    return self;
}

- (void)dealloc
{
    [_foundPrinters release];
    [_browser release];
    [_currentHostName release];
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _foundPrinters.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FasTReceiptPrintersTableCell"];
    if ([indexPath row] > 0) {
        NSNetService *printer = _foundPrinters[indexPath.row-1];
        [cell.textLabel setText:printer.name];
        [cell.detailTextLabel setText:printer.hostName];
        if ([_currentHostName isEqualToString:printer.hostName]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
    } else {
        [cell.textLabel setText:NSLocalizedStringByKey(@"noPrinter")];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.row > 0) {
        NSNetService *printer = _foundPrinters[indexPath.row-1];
        [defaults setValue:printer.hostName forKey:@"FasTReceiptPrinterHostname"];
        [defaults setValue:@(printer.port) forKey:@"FasTReceiptPrinterPort"];
        [ESCPrinter initSharedPrinterWithHost:printer.hostName port:printer.port];
    } else {
        [defaults removeObjectForKey:@"FasTReceiptPrinterHostname"];
    }
    
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark - net service browser delegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [[aNetService retain] setDelegate:self];
    [aNetService resolveWithTimeout:5];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [_foundPrinters removeObject:aNetService];
    if (!moreComing) [[self tableView] reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [_foundPrinters addObject:sender];
    [sender release];
    [[self tableView] reloadData];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    [sender release];
}

@end
