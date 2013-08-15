//
//  FasTCashDrawer.h
//  FasT-box-office
//
//  Created by Albrecht Oster on 16.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MKNetworkEngine;

@interface FasTCashDrawer : NSObject
{
    MKNetworkEngine *netEngine;
}

+ (id)defaultCashDrawer;
- (void)setHostName:(NSString *)hostName;
- (void)updateHostNameFromPrefs;
- (void)identify;
- (void)open;

@end
