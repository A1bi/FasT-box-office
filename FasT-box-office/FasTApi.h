//
//  FasTApi.h
//  FasT-retail
//
//  Created by Albrecht Oster on 09.05.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const FasTApiIsReadyNotification;

typedef void (^FasTApiResponseBlock)(NSDictionary *response);

@class FasTEvent;
@class FasTOrder;
@class AFHTTPSessionManager;

@interface FasTApi : NSObject
{
    AFHTTPSessionManager *http;
    NSDictionary *events;
    NSString *clientType;
    NSString *clientId;
    NSString *seatingId;
}

@property (nonatomic, readonly) NSDictionary *events;
@property (nonatomic, readonly) NSString *clientType;
@property (nonatomic, readonly) NSString *clientId;

+ (FasTApi *)defaultApi;
+ (FasTApi *)defaultApiWithClientType:(NSString *)cType clientId:(NSString *)cId;

- (void)fetchEvents:(void (^)(void))callback;
- (void)getResource:(NSString *)resource withAction:(NSString *)action callback:(FasTApiResponseBlock)callback;
- (void)getResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)postResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)fetchPrintableForTickets:(NSArray *)tickets callback:(void (^)(NSData *))callback;
- (void)pickUpTickets:(NSArray *)tickets;
- (void)finishPurchase:(NSDictionary *)info;
- (void)placeOrder:(FasTOrder *)order callback:(void (^)(FasTOrder *order))callback;
- (NSString *)URLForOrder:(FasTOrder *)order;
- (void)setDate:(NSString *)dateId numberOfSeats:(NSInteger)numberOfSeats callback:(FasTApiResponseBlock)callback;
- (void)resetSeating;
- (void)cancelBoxOfficeOrder:(FasTOrder *)order;
- (void)cancelTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *order))callback;
- (void)enableResaleForTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *order))callback;
- (FasTEvent *)event;

@end
