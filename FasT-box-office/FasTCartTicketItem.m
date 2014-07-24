//
//  FasTCartTicketItem.m
//  FasT-box-office
//
//  Created by Albrecht Oster on 24.07.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "FasTCartTicketItem.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"

@implementation FasTCartTicketItem

- (id)initWithTicket:(FasTTicket *)ticket
{
    self = [super init];
    if (self) {
        _ticket = [ticket retain];
    }
    return self;
}

- (float)price
{
    return _ticket.price;
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"#%@ %@", _ticket.number, _ticket.type.name];
}

- (void)increaseQuantity
{
}

- (void)setQuantity:(NSInteger)quantity
{
}

@end
