//
//  FasTSeatingView.h
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <WebKit/WebKit.h>

@class FasTEventDate;

@interface FasTSeatingView : WKWebView <WKScriptMessageHandler>

@property (nonatomic, readonly) NSString *socketId;

- (id)init;
- (void)setDate:(FasTEventDate *)date numberOfSeats:(NSInteger)numberOfSeats;
- (void)resetSeats;
- (void)validate:(void (^)(BOOL))completion;

@end
