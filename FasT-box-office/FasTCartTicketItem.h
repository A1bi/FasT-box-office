//
//  FasTCartTicketItem.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTCartItem.h"

@class FasTTicket;

@interface FasTCartTicketItem : FasTCartItem

@property (nonatomic, readonly) FasTTicket *ticket;

- (id)initWithTicket:(FasTTicket *)ticket;

@end
