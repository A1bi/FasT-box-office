//
//  EPSPrinter.h
//  PrinterTest
//
//  Created by Albrecht Oster on 15.01.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, EPSPrinterAlignment) {
    EPSPrinterAlignmentLeft,
    EPSPrinterAlignmentCenter,
    EPSPrinterAlignmentRight
};

typedef NS_OPTIONS(uint8_t, EPSPrinterPrintMode) {
    EPSPrinterPrintModeNone         = 0,
    EPSPrinterPrintModeFontB        = 1,
    EPSPrinterPrintModeEmphasized   = 1 << 3,
    EPSPrinterPrintModeDoubleTall   = 1 << 4,
    EPSPrinterPrintModeDoubleWide   = 1 << 5,
    EPSPrinterPrintModeUnderline    = 1 << 7
};

typedef NS_ENUM(uint8_t, EPSPrinterCharacterSet) {
    EPSPrinterCharacterSetAmerica,
    EPSPrinterCharacterSetFrance,
    EPSPrinterCharacterSetGermany,
    EPSPrinterCharacterSetUK
};

@protocol EPSPrinterDelegate;

@interface EPSPrinter : NSObject <NSStreamDelegate>
{
    CFHostRef host;
    NSInteger port;
    NSInputStream *input;
    NSOutputStream *output;
    BOOL spaceAvailable, connected;
    NSMutableData *outputData;
    NSUInteger dataIndex;
    BOOL coverOpened, drawerOpened, paperOut, paperNearEnd;
    uint8_t lineSpacing;
}

@property (nonatomic, assign) id<EPSPrinterDelegate> delegate;

+ (id)initSharedPrinterWithHost:(NSString *)host port:(NSInteger)port;
+ (id)sharedPrinter;
- (void)feed;
- (void)feedLines:(uint8_t)lines;
- (void)cut;
- (void)text:(NSString *)text;
#if TARGET_OS_IPHONE
- (void)image:(UIImage *)image;
#else
- (void)image:(NSImage *)image;
#endif
- (void)setAlignment:(EPSPrinterAlignment)alignment;
- (void)setCharacterSet:(EPSPrinterCharacterSet)set;
- (void)setPrintMode:(EPSPrinterPrintMode)mode;
- (void)setLineSpacing:(uint8_t)spacing;
- (void)setTabPositions:(NSArray *)positions;
- (void)openCashDrawer;

@end

@protocol EPSPrinterDelegate <NSObject>

@optional
- (void)printer:(EPSPrinter *)printer paperOut:(BOOL)paperOut nearEnd:(BOOL)nearEnd;
- (void)printer:(EPSPrinter *)printer coverOpen:(BOOL)coverOpen;
- (void)printer:(EPSPrinter *)printer drawerOpen:(BOOL)drawerOpen;

@end
