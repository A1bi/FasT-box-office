//
//  FasTProduct.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTCartProductItem;

@interface FasTProduct : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) float price;
@property (nonatomic, assign) FasTCartProductItem *cartItem;
@property (nonatomic, readonly) NSString *productId;

- (id)initWithId:(NSString *)pId name:(NSString *)name price:(float)price;

@end
