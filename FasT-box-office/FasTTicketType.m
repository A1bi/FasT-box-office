//
//  FasTTicketType.m
//  FasT-retail
//
//  Created by Albrecht Oster on 29.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTTicketType.h"
#import "FasTFormatter.h"

@implementation FasTTicketType

@synthesize name, info, typeId, price, availability;

- (id)initWithInfo:(NSDictionary *)i
{
    self = [super init];
    if (self) {
        typeId = [i[@"id"] retain];
        name = [i[@"name"] retain];
        info = [i[@"info"] retain];
        price = [i[@"price"] floatValue];

        if ([i[@"availability"] isEqualToString:@"exclusive"]) {
            availability = FasTTicketTypeAvailabilityExclusive;
        } else if ([i[@"availability"] isEqualToString:@"box_office"]) {
            availability = FasTTicketTypeAvailabilityBoxOffice;
        } else {
            availability = FasTTicketTypeAvailabilityUniversal;
        }
    }
    return self;
}

- (void)dealloc
{
    [name release];
    [info release];
    [typeId release];
    [super dealloc];
}

- (NSString *)localizedPrice
{
    return [FasTFormatter stringForPrice:price];
}

@end
