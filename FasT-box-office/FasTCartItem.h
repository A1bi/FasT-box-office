//
//  FasTCartItem.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTCartItem : NSObject

@property (nonatomic, readonly) float price;
@property (nonatomic) NSInteger quantity;
@property (nonatomic, readonly) float total;
@property (nonatomic, readonly) NSString *name;

- (void)increaseQuantity;
- (void)decreaseQuantity;

@end