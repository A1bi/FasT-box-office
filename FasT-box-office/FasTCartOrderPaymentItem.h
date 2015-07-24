//
//  FasTCartRefundItem.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 17.07.15.
//  Copyright (c) 2015 Albisigns. All rights reserved.
//

#import "FasTCartItem.h"

@class FasTOrder;

@interface FasTCartOrderPaymentItem : FasTCartItem

- (id)initWithAmount:(float)amount order:(FasTOrder *)order;

@end
