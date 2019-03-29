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
#import "FasTFormatter.h"

@implementation FasTCartTicketItem

- (id)initWithTicket:(FasTTicket *)ticket
{
    self = [super init];
    if (self) {
        _ticket = [ticket retain];
    }
    return self;
}

- (void)dealloc
{
    [_ticket release];
    [super dealloc];
}

- (float)price
{
    return _ticket.price;
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"%@ (#%@)", _ticket.type.name, _ticket.number];
}

- (NSArray *)printableDescriptionLines
{
    return @[
             @[
                 self.name,
                 @"",
                 [FasTFormatter stringForPrice:self.price]
             ],
             @[
                 @"Ticket bezahlt"
             ]
           ];
}

- (NSString *)productId
{
    return _ticket.ticketId;
}

- (NSString *)type
{
    return @"ticket";
}

- (void)increaseQuantity
{
}

- (void)setQuantity:(NSInteger)quantity
{
}

@end
