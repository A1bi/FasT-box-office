//
//  FasTReceiptPrinter.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTReceiptPrinter.h"
#import "FasTCartItem.h"
#import "FasTFormatter.h"
#import <iZettleSDK/iZettleSDK.h>

@interface ESCPrinter ()

- (id)initWithHost:(NSString *)hostname port:(NSInteger)p;

@end

@interface FasTReceiptPrinter ()

- (void)printHeader;
- (void)printCartItems:(NSArray *)cartItems;
- (void)printFooter;
- (void)printReceiptForCartItems:(NSArray *)cartItems withPaymentBlock:(void (^)())paymentBlock;

@end

@implementation FasTReceiptPrinter

+ (FasTReceiptPrinter *)sharedPrinter
{
    return (FasTReceiptPrinter *)[super sharedPrinter];
}

- (id)initWithHost:(NSString *)hostname port:(NSInteger)p
{
    self = [super initWithHost:hostname port:p];
    if (self) {
        _headerImage = [[UIImage imageNamed:@"ReceiptHeaderImage.jpg"] retain];
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return self;
}

- (void)dealloc
{
    [_headerImage release];
    [super dealloc];
}

- (void)printHeader
{
    [self setAlignment:ESCPrinterAlignmentCenter];
    [self image:_headerImage];
    [self setFont:ESCPrinterFontB adjustLineSpacing:YES];
    [self text:@"www.theater-kaisersesch.de"];
    [self feedLines:2];
    [self setAlignment:ESCPrinterAlignmentLeft];
    [self text:[NSString stringWithFormat:@"%@", [_dateFormatter stringFromDate:[NSDate date]]]];
    [self feed];
    [self text:@"Abendkasse"];
    [self setFont:ESCPrinterFontA adjustLineSpacing:YES];
}

- (void)printFooter
{
    [self setAlignment:ESCPrinterAlignmentCenter];
    [self setFont:ESCPrinterFontB adjustLineSpacing:YES];
    [self text:@"Wir wünschen Ihnen viel Spaß bei\n„Ladykillers“!\n"];
    [self feedLines:2];
    [self text:@"Freilichtbühne am schiefen Turm e. V.\nPostfach 1262\n56759 Kaisersesch\ninfo@theater-kaisersesch.de\n(02653) 282709"];
}

- (void)printCartItems:(NSArray *)cartItems
{
    uint16_t position[] = {0, 210, 410};
    for (FasTCartItem *cartItem in cartItems) {
        BOOL firstLine = YES;
        [self setFont:ESCPrinterFontA adjustLineSpacing:YES];
        for (NSArray *line in cartItem.printableDescriptionLines) {
            int i = 0;
            for (NSString *column in line) {
                if (position[i] > 0) [self setAbsolutePosition:position[i]];
                [self text:column];
                if (i < 2) i++;
            }
            if (firstLine) {
                [self setFont:ESCPrinterFontB adjustLineSpacing:YES];
                firstLine = NO;
            }
            [self feed];
        }
    }
    NSNumber *total = [cartItems valueForKeyPath:@"@sum.total"];
    [self setAlignment:ESCPrinterAlignmentRight];
    [self setPrintMode:ESCPrinterPrintModeEmphasized | ESCPrinterPrintModeDoubleTall];
    [self text:[NSString stringWithFormat:@"\nSumme: %@", [FasTFormatter stringForPrice:total.floatValue]]];
    [self setPrintMode:ESCPrinterPrintModeNone];
}

- (void)printReceiptForCartItems:(NSArray *)cartItems withPaymentBlock:(void (^)())paymentBlock
{
    [self printHeader];
    [self horizontalLine:YES];
    [self feed];
    [self printCartItems:cartItems];
    paymentBlock();
    [self feed];
    [self horizontalLine:YES];
    [self feed];
    [self printFooter];
    [self cut];
}

- (void)printReceiptForCartItems:(NSArray *)cartItems withCashPaymentInfo:(NSDictionary *)paymentInfo
{
    [self printReceiptForCartItems:cartItems withPaymentBlock:^{
        [self horizontalLine:NO];
        [self setAlignment:ESCPrinterAlignmentRight];
        [self setPrintMode:ESCPrinterPrintModeEmphasized];
        NSString *amount = [FasTFormatter stringForPrice:((NSNumber *)paymentInfo[@"given"]).floatValue];
        [self text:[NSString stringWithFormat:@"Gegeben (Bar): %@", amount]];
        amount = [FasTFormatter stringForPrice:((NSNumber *)paymentInfo[@"change"]).floatValue];
        [self text:[NSString stringWithFormat:@"\nRückgeld (Bar): %@", amount]];
        [self setPrintMode:ESCPrinterPrintModeNone];
    }];
}

- (void)printReceiptForCartItems:(NSArray *)cartItems withElectronicCashPaymentInfo:(iZettleSDKPaymentInfo *)paymentInfo
{
    [self printReceiptForCartItems:cartItems withPaymentBlock:^{
        [self horizontalLine:NO];
        [self setAlignment:ESCPrinterAlignmentRight];
        [self setPrintMode:ESCPrinterPrintModeEmphasized];
        NSNumber *total = [cartItems valueForKeyPath:@"@sum.total"];
        [self text:[NSString stringWithFormat:@"EC-Abbuchung: %@", [FasTFormatter stringForPrice:total.floatValue]]];
        [self feed];
        
        [self setAlignment:ESCPrinterAlignmentCenter];
        [self text:@"\nEC-Zahlung"];
        [self text:[NSString stringWithFormat:@"\n%@", paymentInfo.cardBrand]];
        [self setPrintMode:ESCPrinterPrintModeNone];
        [self text:[NSString stringWithFormat:@"\nPAN: %@", paymentInfo.obfuscatedPan]];
        [self text:[NSString stringWithFormat:@"\nAID: %@", paymentInfo.AID]];
    }];
}

@end
