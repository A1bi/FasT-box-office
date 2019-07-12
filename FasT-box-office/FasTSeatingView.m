//
//  FasTSeatingView.m
//  FasT-retail
//
//  Created by Albrecht Oster on 11.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTSeatingView.h"
#import "FasTEvent.h"
#import "FasTEventDate.h"

@interface FasTSeatingView ()
{
    FasTEventDate *date;
    NSInteger numberOfSeats;
    WKUserContentController *contentController;
}

- (void)reloadSeating;
- (void)updateDateAndNumberOfSeats;
- (void)callScriptMethod:(NSString *)method withParams:(NSString *)params completion:(void (^)(id _Nullable))completion;
- (NSURL *)urlForSeatingWithEvent;

@end

@implementation FasTSeatingView

@synthesize socketId;

- (id)init
{
    WKUserContentController *contentController = [[[WKUserContentController alloc] init] autorelease];
    [contentController addScriptMessageHandler:self name:@"seating"];
    
    WKWebViewConfiguration *config = [[[WKWebViewConfiguration alloc] init] autorelease];
    config.userContentController = contentController;
    
    self = [super initWithFrame:CGRectZero configuration:config];
    return self;
}

- (void)dealloc
{
    [date release];
    [contentController release];
    [super dealloc];
}

- (void)setDate:(FasTEventDate *)d numberOfSeats:(NSInteger)n
{
    if (date == d && numberOfSeats == n) return;
    
    numberOfSeats = n;
    
    FasTEventDate *previousDate = date;
    if (date != d) {
        date = [d retain];
        
        if (previousDate.event != date.event) {
            [self reloadSeating];
        } else {
            [self updateDateAndNumberOfSeats];
        }
        
        [previousDate release];
    }
}

- (void)updateDateAndNumberOfSeats
{
    if (!date || numberOfSeats < 1) return;
    
    NSString *params = [NSString stringWithFormat:@"%@, %ld", date.dateId, (long)numberOfSeats];
    [self callScriptMethod:@"setDateAndNumberOfSeats" withParams:params completion:NULL];
}

- (void)resetSeats
{
    [self callScriptMethod:@"reset" withParams:nil completion:NULL];
}

- (void)validate:(void (^)(BOOL))completion
{
    [self callScriptMethod:@"validate" withParams:nil completion:^(id result) {
        if (completion) completion([(NSNumber *)result boolValue]);
    }];
}

- (void)callScriptMethod:(NSString *)method withParams:(NSString *)params completion:(void (^)(id _Nullable))completion
{
    if (!params) params = @"";
    NSString *script = [NSString stringWithFormat:@"seating.%@(%@);", method, params];
    [self evaluateJavaScript:script completionHandler:^(id result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.description);
        } else if (completion) {
            completion(result);
        }
    }];
}

- (void)reloadSeating
{
    NSURL *url = [self urlForSeatingWithEvent];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self loadRequest:request];
}

- (NSURL *)urlForSeatingWithEvent
{
    NSString *url = [NSString stringWithFormat:@"%@/api/ticketing/box_office/seating?event_id=%@", API_HOST, date.event.eventId];
    return [NSURL URLWithString:url];
}

#pragma mark script message handler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary *data = (NSDictionary *)message.body;
    if ([data[@"event"] isEqualToString:@"becameReady"]) {
        [socketId release];
        socketId = [data[@"socketId"] retain];
        
        [self updateDateAndNumberOfSeats];
    }
}

@end
