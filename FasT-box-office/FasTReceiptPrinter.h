//
//  FasTReceiptPrinter.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "ESCPrinter.h"

@class FasTFormatter;

@interface FasTReceiptPrinter : ESCPrinter
{
    UIImage *_headerImage;
    NSDateFormatter *_dateFormatter;
    FasTFormatter *_formatter;
}

+ (FasTReceiptPrinter *)sharedPrinter;
- (void)printReceiptForCartItems:(NSArray *)cartItems;

@end
