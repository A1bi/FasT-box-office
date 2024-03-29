//
//  FasTApi.m
//  FasT-retail
//
//  Created by Albrecht Oster on 09.05.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#ifndef API_AUTH_TOKEN
#error "API Auth Token not set"
#endif

#import "FasTApi.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"
#import "FasTSeatingView.h"

@import AFNetworking;

NSString * const FasTApiIsReadyNotification = @"FasTApiIsReadyNotification";

static FasTApi *defaultApi = nil;

#define kFasTApiTimeOut 10

@interface FasTApi ()

- (void)makeJsonRequestWithPath:(NSString *)path method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)makeJsonRequestWithResource:(NSString *)resource action:(NSString *)action method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)patchTickets:(NSArray *)tickets data:(NSDictionary *)data callback:(void (^)(void))callback;
- (void)postNotificationWithName:(NSString *)name info:(NSDictionary *)info;
- (NSArray *)ticketIdsForTickets:(NSArray *)tickets;

@end

@implementation FasTApi

@synthesize events, seatingView;

+ (FasTApi *)defaultApi
{
    if (!defaultApi) {
        defaultApi = [[super allocWithZone:NULL] init];
    }
    return defaultApi;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self defaultApi] retain];
}

- (id)init
{
    self = [super init];
    if (self) {
        http = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:API_HOST]];
        
        [http setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [http setResponseSerializer:[AFJSONResponseSerializer serializer]];
        
        NSString *auth = [NSString stringWithFormat:@"Token %@", API_AUTH_TOKEN];
        [http.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];

        seatingView = [[FasTSeatingView alloc] init];

        [self fetchEvents:NULL];
    }
    return self;
}

- (void)dealloc
{
    [http release];
    [events release];
    [seatingView release];
    [super dealloc];
}

#pragma mark - rails api methods

- (void)getResource:(NSString *)resource withAction:(NSString *)action callback:(FasTApiResponseBlock)callback
{
    [self getResource:resource withAction:action data:nil callback:callback];
}

- (void)getResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback
{
    [self makeJsonRequestWithResource:resource action:action method:@"GET" data:data callback:callback];
}

- (void)postResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback
{
    [self makeJsonRequestWithResource:resource action:action method:@"POST" data:data callback:callback];
}

- (void)makeJsonRequestWithResource:(NSString *)resource action:(NSString *)action method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback
{
    NSString *path = (action) ? [NSString stringWithFormat:@"/%@/%@", resource, action] : [NSString stringWithFormat:@"/%@", resource];
    [self makeJsonRequestWithPath:path method:method data:data callback:callback];
}

- (void)makeJsonRequestWithPath:(NSString *)path method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback
{
    void(^success)(NSURLSessionDataTask *task, id responseObject) = ^(NSURLSessionDataTask *task, id responseObject) {
        if (callback) {
            callback(responseObject);
        }
    };
    
    void(^failure)(NSURLSessionDataTask *task, NSError *error) = ^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"%@", error);
        if (callback) {
            callback(nil);
        }
    };
    
    if ([method isEqualToString:@"POST"]) {
        [http POST:path parameters:data progress:nil success:success failure:failure];
    } else if ([method isEqualToString:@"PATCH"]) {
        [http PATCH:path parameters:data success:success failure:failure];
    } else if ([method isEqualToString:@"DELETE"]) {
        [http DELETE:path parameters:data success:success failure:failure];
    } else {
        [http GET:path parameters:data progress:nil success:success failure:failure];
    }
}

- (void)cancelBoxOfficeOrder:(FasTOrder *)order
{
    [self makeJsonRequestWithResource:@"api/ticketing/box_office/orders" action:order.orderId method:@"DELETE" data:nil callback:NULL];
}

- (void)patchTickets:(NSArray *)tickets data:(NSDictionary *)data callback:(void (^)(void))callback
{
    NSArray *ticketIds = [self ticketIdsForTickets:tickets];
    NSDictionary *requestData = @{ @"ids": ticketIds, @"ticket": data };
    
    [self makeJsonRequestWithPath:@"api/ticketing/box_office/tickets" method:@"PATCH" data:requestData callback:^(NSDictionary *response) {
        if (callback) callback();
    }];
}

- (void)cancelTickets:(NSArray *)tickets callback:(void (^)(void))callback
{
    [self patchTickets:tickets data:@{ @"cancelled": @(YES) } callback:callback];
}

- (void)enableResaleForTickets:(NSArray *)tickets callback:(void (^)(void))callback
{
    [self patchTickets:tickets data:@{ @"resale": @(YES) } callback:callback];
}

- (void)pickUpTickets:(NSArray *)tickets callback:(void (^)(void))callback
{
    [self patchTickets:tickets data:@{ @"picked_up": @(YES) } callback:callback];
}

#pragma mark class methods

- (void)fetchEvents:(void (^)(void))callback
{
    NSMutableDictionary *tmpEvents = [NSMutableDictionary dictionary];
    [self getResource:@"api/ticketing/box_office/events" withAction:nil callback:^(NSDictionary *response) {
        for (NSDictionary *eventInfo in response[@"events"]) {
            FasTEvent *event = [[[FasTEvent alloc] initWithInfo:eventInfo] autorelease];
            tmpEvents[event.eventId] = event;
        }
        [events release];
        events = [[NSDictionary dictionaryWithDictionary:tmpEvents] retain];
        
        if (callback) callback();
    }];
}

- (void)placeOrder:(FasTOrder *)order callback:(void (^)(FasTOrder *order))callback
{
    NSMutableDictionary *ticketsInfo = [NSMutableDictionary dictionary];
    for (FasTTicket *ticket in order.tickets) {
        NSInteger number = 0;
        if (ticketsInfo[ticket.type.typeId]) {
            number = ((NSNumber *)ticketsInfo[ticket.type.typeId]).integerValue;
        }
        number++;
        ticketsInfo[ticket.type.typeId] = @(number);
    }
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"box_office_id"] = @(1);
    data[@"socket_id"] = seatingView.socketId;
    data[@"order"] = @{ @"date": order.date.dateId, @"tickets": ticketsInfo };
    
    [self makeJsonRequestWithPath:@"api/ticketing/box_office/orders" method:@"POST" data:data callback:^(NSDictionary *response) {
        if (!response) {
            callback(nil);
            return;
        }

        FasTOrder *newOrder = [[[FasTOrder alloc] initWithInfo:response[@"order"]] autorelease];
        callback(newOrder);
    }];
}

- (void)fetchPrintableForTickets:(NSArray *)tickets callback:(void (^)(NSData *data))callback
{
    NSArray *ticketIds = [self ticketIdsForTickets:tickets];
    [http GET:@"api/ticketing/box_office/tickets.pdf" parameters:@{ @"ids": ticketIds } progress:nil success:NULL failure:^(NSURLSessionDataTask *task, NSError *error) {
        if ([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
            NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            callback(data);
        }
    }];
}

- (void)finishPurchase:(NSDictionary *)data
{
    [self makeJsonRequestWithPath:@"api/ticketing/box_office/purchases" method:@"POST" data:data callback:NULL];
}

- (void)resetSeating
{
    [seatingView resetSeats];
}

- (NSString *)URLForOrder:(FasTOrder *)order
{
    return [NSString stringWithFormat:@"%@/vorverkauf/bestellungen/%@", API_HOST, order.orderId];
}

- (NSArray *)ticketIdsForTickets:(NSArray *)tickets
{
    NSMutableArray *ticketIds = [NSMutableArray array];
    for (FasTTicket *ticket in tickets) {
        [ticketIds addObject:ticket.ticketId];
    }
    return ticketIds;
}

- (void)postNotificationWithName:(NSString *)name info:(NSDictionary *)info
{
    NSNotification *notification = [NSNotification notificationWithName:name object:self userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
