//
//  FasTCartProductItem.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTCartProductItem.h"
#import "FasTProduct.h"

@implementation FasTCartProductItem

- (id)initWithProduct:(FasTProduct *)product
{
    self = [super init];
    if (self) {
        _product = [product retain];
        _product.cartItem = self;
    }
    return self;
}

- (void)dealloc
{
    _product.cartItem = nil;
    [_product release];
    [super dealloc];
}

- (float)price
{
    return _product.price;
}

- (NSString *)name
{
    return _product.name;
}

@end
