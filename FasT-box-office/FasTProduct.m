//
//  FasTProduct.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTProduct.h"

@implementation FasTProduct

- (id)initWithName:(NSString *)name price:(float)price
{
    self = [super init];
    if (self) {
        _name = [name retain];
        _price = price;
    }
    return self;
}

@end
