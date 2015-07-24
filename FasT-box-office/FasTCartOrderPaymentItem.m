//
//  FasTCartRefundItem.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTCartOrderPaymentItem.h"
#import "FasTOrder.h"
#import "FasTFormatter.h"

@interface FasTCartOrderPaymentItem ()
{
    FasTOrder *_order;
    float _amount;
}

@end

@implementation FasTCartOrderPaymentItem

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
    return _amount;
}

- (NSString *)name
{
    NSString *caption = _amount > 0 ? @"Differenz" : @"Erstattung";
    return [NSString stringWithFormat:@"%@ (#%@)", caption, _order.number];
}

- (NSArray *)printableDescriptionLines
{
    NSString *caption = _amount > 0 ? @"Differenzzahlung" : @"Erstattung";
    return @[
             @[
                 caption,
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
    return @{ @"type": @"order_payment", @"amount": @(_amount), @"order": _order.orderId };
}

- (void)increaseQuantity
{
}

- (void)setQuantity:(NSInteger)quantity
{
}

@end
