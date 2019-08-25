//
//  FasTOrder.m
//  FasT-retail
//
//  Created by Albrecht Oster on 14.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTOrder.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTTicket.h"
#import "FasTLogEvent.h"
#import "FasTFormatter.h"
#import "FasTApi.h"

@implementation FasTOrder

@synthesize orderId, number, date, tickets, createdAt, total, balance, paid, firstName, lastName, logEvents;

- (id)initWithInfo:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        orderId = [info[@"id"] retain];
        number = [info[@"number"] retain];
        total = [info[@"total"] floatValue];
        balance = [info[@"balance"] floatValue];
        paid = [info[@"paid"] boolValue];
        createdAt = [[NSDate dateWithTimeIntervalSince1970:[info[@"created_at"] intValue]] retain];
        firstName = [info[@"first_name"] retain];
        lastName = [info[@"last_name"] retain];
        
        NSDictionary *itemInfo;
        logEvents = [[NSMutableArray alloc] init];
        for (itemInfo in info[@"log_events"]) {
            [logEvents addObject:[[[FasTLogEvent alloc] initWithInfo:itemInfo] autorelease]];
        }
        
        FasTEvent *event = [FasTApi defaultApi].events[info[@"event_id"]];
        
        NSMutableArray *tmpTickets = [NSMutableArray array];
        for (itemInfo in info[@"tickets"]) {
            FasTEventDate *d = [event objectFromArray:@"dates" withId:itemInfo[@"date_id"] usingIdName:@"date"];
            FasTTicket *ticket = [[[FasTTicket alloc] initWithInfo:itemInfo date:d order:self] autorelease];
            [tmpTickets addObject:ticket];
        }
        tickets = [[NSArray arrayWithArray:tmpTickets] retain];
    }
    return self;
}

- (void)dealloc
{
    [orderId release];
    [number release];
	[tickets release];
    [date release];
    [createdAt release];
    [firstName release];
    [lastName release];
    [logEvents release];
	[super dealloc];
}

- (id)valueForKey:(NSString *)key
{
    id value = [super valueForKey:key];
    if (([key isEqualToString:@"firstName"] || [key isEqualToString:@"lastName"]) && (![value isKindOfClass:[NSString class]] || [value length] < 1)) {
        value = NSLocalizedStringByKey(@"notSpecified");
    }
    return value;
}

- (NSInteger)numberOfTickets
{
    NSInteger t = 0;
    for (FasTTicket *ticket in tickets) {
        if (!ticket.cancelled) t++;
    }
    return t;
}

- (NSString *)fullNameWithLastNameFirst:(BOOL)flag
{
    NSString *ln = [self valueForKey:@"lastName"], *fn = [self valueForKey:@"firstName"];
    return flag ? [NSString stringWithFormat:@"%@, %@", ln, fn] : [NSString stringWithFormat:@"%@ %@", fn, ln];
}

- (NSString *)localizedTotal
{
    return [FasTFormatter stringForPrice:total];
}

- (NSString *)localizedBalance
{
    return [FasTFormatter stringForPrice:balance];
}

- (BOOL)cancelled
{
    return [self numberOfTickets] < 1;
}

@end
