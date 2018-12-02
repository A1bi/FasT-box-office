//
//  FasTSeat.m
//  FasT-retail
//
//  Created by Albrecht Oster on 29.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSeat.h"

@implementation FasTSeat

@synthesize seatId, number, row, blockName, taken, chosen;

- (id)initWithInfo:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        seatId = [info[@"id"] retain];
        number = [info[@"number"] retain];
        if (![info[@"row"] isEqual:[NSNull null]]) {
            row = [info[@"row"] retain];
        }
        if (![info[@"block_name"] isEqual:[NSNull null]]) {
            blockName = [info[@"block_name"] retain];
        }
    }
    return self;
}

- (NSString *)fullNumber
{
    return [NSString stringWithFormat:@"%@%@", blockName ? blockName : @"", number];
}

- (void)dealloc
{
    [seatId release];
    [number release];
    [row release];
    [blockName release];
    [super dealloc];
}

- (void)updateWithInfo:(NSDictionary *)info
{
    taken = [info[@"t"] boolValue];
    chosen = [info[@"c"] boolValue];
}

@end
