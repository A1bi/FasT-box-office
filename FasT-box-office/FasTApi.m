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

@import SocketIO;
@import AFNetworking;

NSString * const FasTApiIsReadyNotification = @"FasTApiIsReadyNotification";
NSString * const FasTApiUpdatedSeatsNotification = @"FasTApiUpdatedSeatsNotification";
NSString * const FasTApiUpdatedOrdersNotification = @"FasTApiUpdatedOrdersNotification";
NSString * const FasTApiOrderExpiredNotification = @"FasTApiOrderExpiredNotification";
NSString * const FasTApiConnectingNotification = @"FasTApiConnectingNotification";
NSString * const FasTApiDisconnectedNotification = @"FasTApiDisconnectedNotification";
NSString * const FasTApiCannotConnectNotification = @"FasTApiCannotConnectNotification";

static FasTApi *defaultApi = nil;

#define kFasTApiTimeOut 10

@interface FasTApi ()

- (id)initWithClientType:(NSString *)cType clientId:(NSString *)cId;
- (void)makeJsonRequestWithPath:(NSString *)path method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)makeJsonRequestWithResource:(NSString *)resource action:(NSString *)action method:(NSString *)method data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)makeRequestWithAction:(NSString *)action method:(NSString *)method tickets:(NSArray *)tickets callback:(void (^)(FasTOrder *))callback;
- (void)connectToNode;
- (void)postNotificationWithName:(NSString *)name info:(NSDictionary *)info;
- (void)prepareNodeConnection;
- (void)disconnect;
- (void)scheduleReconnect;
- (void)abortAndReconnect;
- (void)killScheduledTasks;
- (void)appWillResignActive;
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
    [sIO release];
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

- (void)resetSeating
{
    if (seatingId) {
        [sIO emit:@"reset" with:@[]];
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

#pragma mark node methods

- (void)setDate:(NSString *)dateId numberOfSeats:(NSInteger)numberOfSeats callback:(FasTApiResponseBlock)callback
{
    NSDictionary *data = @{ @"date": dateId, @"numberOfSeats": @(numberOfSeats) };
    OnAckCallback *ackCallback = [sIO emitWithAck:@"setDateAndNumberOfSeats" with:@[data]];
    [ackCallback timingOutAfter:5 callback:^(NSArray *data) {
        NSDictionary *response = data.count > 0 ? data[0] : nil;
        callback(response);
    }];
}

- (void)chooseSeatWithId:(NSString *)seatId
{
    NSDictionary *data = @{ @"seatId": seatId };
    [sIO emit:@"chooseSeat" with:@[data]];
}

- (void)connectToNode
{
    [sIO connect];
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

- (void)initNodeConnection
{
    if (nodeConnectionInitiated) return;
    nodeConnectionInitiated = true;
    
    NSURL *url = [NSURL URLWithString:API_HOST];
    NSDictionary *options = @{@"log": @YES, @"path": @"/node/", @"nsp": [NSString stringWithFormat:@"/%@", clientType]};
    sIO = [[SocketIOClient alloc] initWithSocketURL:url config:options];
    
    inHibernation = YES;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:self selector:@selector(disconnect) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(prepareNodeConnection) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self prepareNodeConnection];
    
    [sIO on:@"connect" callback:^(NSArray *args, SocketAckEmitter *ack) {
        [self killScheduledTasks];
        
        [self postNotificationWithName:FasTApiIsReadyNotification info:nil];
    }];
    
    [sIO on:@"disconnect" callback:^(NSArray *args, SocketAckEmitter *ack) {
        [self killScheduledTasks];
        if (inHibernation) return;
        
        [self postNotificationWithName:FasTApiDisconnectedNotification info:nil];
        
        [self scheduleReconnect];
    }];
    
    [sIO on:@"error" callback:^(NSArray *args, SocketAckEmitter *ack) {
        [self killScheduledTasks];
        if (inHibernation) return;
    
        [self postNotificationWithName:FasTApiCannotConnectNotification info:nil];
    
        [self scheduleReconnect];
    }];
    
    
    [sIO on:@"updateSeats" callback:^(NSArray *args, SocketAckEmitter *ack) {
        NSDictionary *seats = args[0][@"seats"];
        [self.event updateSeats:seats];

        [self postNotificationWithName:FasTApiUpdatedSeatsNotification info:seats];
    }];
    
    [sIO on:@"gotSeatingId" callback:^(NSArray *args, SocketAckEmitter *ack) {
        [seatingId release];
        seatingId = [args[0][@"id"] retain];
    }];
    
    [sIO on:@"expired" callback:^(NSArray *args, SocketAckEmitter *ack) {
        [self postNotificationWithName:FasTApiOrderExpiredNotification info:nil];
    }];
}

- (void)postNotificationWithName:(NSString *)name info:(NSDictionary *)info
{
    NSNotification *notification = [NSNotification notificationWithName:name object:self userInfo:info];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)prepareNodeConnection
{
    if (!clientType) return;
    
    [self killScheduledTasks];
//    [self performSelector:@selector(abortAndReconnect) withObject:nil afterDelay:kFasTApiTimeOut];
    
    if (inHibernation) [self postNotificationWithName:FasTApiConnectingNotification info:nil];
    inHibernation = NO;
    [self fetchEvents:^() {
        [self connectToNode];
    }];
}

- (void)disconnect
{
    inHibernation = YES;
//    [netEngine cancelAllOperations];
    [sIO disconnect];
}

- (void)abortAndReconnect
{
    [self disconnect];
    inHibernation = NO;
    [self scheduleReconnect];
    
    [self postNotificationWithName:FasTApiCannotConnectNotification info:nil];
}

- (void)killScheduledTasks
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)scheduleReconnect
{
    [self performSelector:@selector(prepareNodeConnection) withObject:nil afterDelay:5];
}

- (void)appWillResignActive
{
    [self killScheduledTasks];
}

- (FasTEvent *)event
{
    return (FasTEvent *)events.allValues.lastObject;
}

@end
