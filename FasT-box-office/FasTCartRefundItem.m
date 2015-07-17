//
//  FasTCartRefundItem.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTCartRefundItem.h"
#import "FasTOrder.h"
#import "FasTFormatter.h"

@interface FasTCartRefundItem ()
{
    FasTOrder *_order;
    float _amount;
}

@end

@implementation FasTCartRefundItem

- (id)initWithAmount:(float)amount order:(FasTOrder *)order
{
    self = [super init];
    if (self) {
        _amount = amount;
        _order = [order retain];
    }
    return self;
}

- (void)dealloc
{
    [_order release];
    [super dealloc];
}

- (float)price
{
    return -_amount;
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"Erstattung (#%@)", _order.number];
}

- (NSArray *)printableDescriptionLines
{
    return @[
             @[
                 @"Erstattung",
                 @"",
                 [FasTFormatter stringForPrice:self.price]
                 ],
             @[
                 [NSString stringWithFormat:@"Bestellung %@", _order.number]
                 ]
             ];
}

- (NSDictionary *)apiInfo
{
    return @{ @"type": @"refund", @"amount": @(_amount), @"order": _order.orderId };
}

- (void)increaseQuantity
{
}

- (void)setQuantity:(NSInteger)quantity
{
}

@end
