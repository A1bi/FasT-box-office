//
//  FasTApi.m
//  FasT-retail
//
//  Created by Albrecht Oster on 09.05.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTApi.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"
#import "FasTOrder.h"
#import "FasTTicket.h"
#import "FasTTicketType.h"

@import AFNetworking;

NSString * const FasTApiIsReadyNotification = @"FasTApiIsReadyNotification";

static FasTApi *defaultApi = nil;

#define kFasTApiTimeOut 10

@interface FasTApi ()

- (id)initWithClientType:(NSString *)cType clientId:(NSString *)cId;
- (void)makeJsonRequestWithPath:(NSString *)path method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)makeJsonRequestWithResource:(NSString *)resource action:(NSString *)action method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)makeRequestWithAction:(NSString *)action method:(NSString *)method tickets:(NSArray *)tickets callback:(void (^)(FasTOrder *))callback;
- (void)postNotificationWithName:(NSString *)name info:(NSDictionary *)info;
- (NSArray *)ticketIdsForTickets:(NSArray *)tickets;

@end

@implementation FasTApi

@synthesize events, clientType, clientId;

+ (FasTApi *)defaultApi
{
	if (!defaultApi) {
        [NSException raise:@"FasTApiNotInitiatedException" format:@"FasTApi has to be initiated by sending initWithClientType: first."];
        return nil;
    }
	
	return defaultApi;
}

+ (FasTApi *)defaultApiWithClientType:(NSString *)cType clientId:(NSString *)cId
{
    if (!defaultApi) {
        defaultApi = [[super allocWithZone:NULL] initWithClientType:cType clientId:cId];
    }
    return defaultApi;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self defaultApi] retain];
}

- (id)init
{
    return defaultApi;
}

- (id)initWithClientType:(NSString *)cType clientId:(NSString *)cId
{
    self = [super init];
    if (self) {
        http = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:API_HOST]];
        [http setRequestSerializer:[AFJSONRequestSerializer serializer]];
        [http setResponseSerializer:[AFJSONResponseSerializer serializer]];
        
        clientType = [cType retain];
        clientId = [cId retain];
    }
    return self;
}

- (void)dealloc
{
    [http release];
    [events release];
    [clientType release];
    [clientId release];
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
    } else {
        [http GET:path parameters:data progress:nil success:success failure:failure];
    }
}

- (void)unlockSeats
{
    if (seatingId) {
        [self makeJsonRequestWithPath:@"api/box_office/unlock_seats" method:@"POST" data:@{ @"seating_id": seatingId } callback:NULL];
    }
}

- (void)cancelBoxOfficeOrder:(FasTOrder *)order
{
    [self makeJsonRequestWithPath:@"api/box_office/cancel_order" method:@"PATCH" data:@{ @"id": order.orderId } callback:NULL];
}

- (void)makeRequestWithAction:(NSString *)action method:(NSString *)method tickets:(NSArray *)tickets callback:(void (^)(FasTOrder *))callback
{
    NSArray *ticketIds = [self ticketIdsForTickets:tickets];
    
    [self makeJsonRequestWithPath:[NSString stringWithFormat:@"api/box_office/%@", action] method:method data:@{ @"ticket_ids": ticketIds } callback:^(NSDictionary *response) {
        FasTOrder *order = [[[FasTOrder alloc] initWithInfo:response[@"order"] event:self.event] autorelease];
        callback(order);
    }];
}

- (void)cancelTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *order))callback
{
    [self makeRequestWithAction:@"cancel_tickets" method:@"PATCH" tickets:tickets callback:callback];
}

- (void)enableResaleForTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *))callback
{
    [self makeRequestWithAction:@"enable_resale_for_tickets" method:@"PATCH" tickets:tickets callback:callback];
}

- (void)setDate:(NSString *)dateId numberOfSeats:(NSInteger)numberOfSeats callback:(FasTApiResponseBlock)callback
{
//    NSDictionary *data = @{ @"date": dateId, @"numberOfSeats": @(numberOfSeats) };
//    OnAckCallback *ackCallback = [sIO emitWithAck:@"setDateAndNumberOfSeats" with:@[data]];
//    [ackCallback timingOutAfter:5 callback:^(NSArray *data) {
//        NSDictionary *response = data.count > 0 ? data[0] : nil;
//        callback(response);
//    }];
}

#pragma mark class methods

- (void)fetchEvents:(void (^)(void))callback
{
    NSMutableDictionary *tmpEvents = [NSMutableDictionary dictionary];
    [self getResource:@"api/box_office" withAction:@"events" callback:^(NSDictionary *response) {
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
    
    NSMutableDictionary *orderInfo = [[@{ @"date": order.date.dateId, @"tickets": ticketsInfo } mutableCopy] autorelease];
    if (seatingId) {
        orderInfo[@"seatingId"] = seatingId;
    }
    
    [self makeJsonRequestWithPath:@"api/box_office/place_order" method:@"POST" data:@{ @"order": orderInfo } callback:^(NSDictionary *response) {
        FasTOrder *newOrder = [[[FasTOrder alloc] initWithInfo:response[@"order"] event:self.event] autorelease];
        callback(newOrder);
    }];
}

- (void)fetchPrintableForTickets:(NSArray *)tickets callback:(void (^)(NSData *data))callback
{
    NSArray *ticketIds = [self ticketIdsForTickets:tickets];
    [http GET:@"api/box_office/ticket_printable" parameters:@{ @"ticket_ids": ticketIds } progress:nil success:NULL failure:^(NSURLSessionDataTask *task, NSError *error) {
        if ([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
            NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            callback(data);
        }
    }];
}

- (void)pickUpTickets:(NSArray *)tickets
{
    for (FasTTicket *ticket in tickets) {
        ticket.pickedUp = YES;
    }
    
    NSDictionary *data = @{ @"ticket_ids": [self ticketIdsForTickets:tickets] };
    [self makeJsonRequestWithResource:@"api/box_office" action:@"pick_up_tickets" method:@"PATCH" data:data callback:NULL];
}

- (void)finishPurchase:(NSDictionary *)data
{
    [self makeJsonRequestWithResource:@"api/box_office" action:@"purchase" method:@"POST" data:data callback:NULL];
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

- (FasTEvent *)event
{
    return (FasTEvent *)events.allValues.lastObject;
}

@end
