//
//  FasTCartProductItem.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTCartItem.h"

@class FasTProduct;

@interface FasTCartProductItem : FasTCartItem

@property (nonatomic, readonly) FasTProduct *product;

- (id)initWithProduct:(FasTProduct *)product;

@end
