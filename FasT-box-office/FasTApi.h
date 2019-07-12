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

@class FasTOrder;
@class FasTSeatingView;
@class AFHTTPSessionManager;

@interface FasTApi : NSObject
{
    AFHTTPSessionManager *http;
    NSDictionary *events;
    FasTSeatingView *seatingView;
}

@property (nonatomic, readonly) NSDictionary *events;
@property (nonatomic, readonly) FasTSeatingView *seatingView;

+ (FasTApi *)defaultApi;

- (void)fetchEvents:(void (^)(void))callback;
- (void)getResource:(NSString *)resource withAction:(NSString *)action callback:(FasTApiResponseBlock)callback;
- (void)getResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)postResource:(NSString *)resource withAction:(NSString *)action data:(NSDictionary *)data callback:(FasTApiResponseBlock)callback;
- (void)fetchPrintableForTickets:(NSArray *)tickets callback:(void (^)(NSData *))callback;
- (void)pickUpTickets:(NSArray *)tickets;
- (void)finishPurchase:(NSDictionary *)info;
- (void)placeOrder:(FasTOrder *)order callback:(void (^)(FasTOrder *order))callback;
- (NSString *)URLForOrder:(FasTOrder *)order;
- (void)resetSeating;
- (void)cancelBoxOfficeOrder:(FasTOrder *)order;
- (void)cancelTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *order))callback;
- (void)enableResaleForTickets:(NSArray *)tickets callback:(void (^)(FasTOrder *order))callback;

@end
