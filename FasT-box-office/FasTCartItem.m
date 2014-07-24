//
//  FasTCartItem.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTCartItem.h"

@implementation FasTCartItem

- (id)init
{
    self = [super init];
    if (self) {
        _quantity = 1;
    }
    return self;
}

- (float)total
{
    return self.price * _quantity;
}

- (void)increaseQuantity
{
    _quantity++;
}

- (void)decreaseQuantity
{
    if (_quantity <= 0) return;
    _quantity--;
}

@end
