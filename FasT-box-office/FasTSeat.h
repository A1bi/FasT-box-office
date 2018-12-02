//
//  FasTSeat.h
//  FasT-retail
//
//  Created by Albrecht Oster on 29.04.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTSeat : NSObject
{
    NSString *seatId;
    NSString *number, *row, *blockName;
    BOOL taken, chosen;
}

@property (nonatomic, readonly) NSString *seatId;
@property (nonatomic, readonly) NSString *number, *row, *blockName;
@property (nonatomic, readonly) BOOL taken, chosen;

- (id)initWithInfo:(NSDictionary *)info;
- (NSString *)fullNumber;
- (void)updateWithInfo:(NSDictionary *)info;

@end
