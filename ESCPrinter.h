//
//  ESCPrinter.h
//  PrinterTest
//
//  Created by Albrecht Oster on 15.01.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, ESCPrinterAlignment) {
    ESCPrinterAlignmentLeft,
    ESCPrinterAlignmentCenter,
    ESCPrinterAlignmentRight
};

typedef NS_OPTIONS(uint8_t, ESCPrinterPrintMode) {
    ESCPrinterPrintModeNone         = 0,
    ESCPrinterPrintModeFontB        = 1,
    ESCPrinterPrintModeEmphasized   = 1 << 3,
    ESCPrinterPrintModeDoubleTall   = 1 << 4,
    ESCPrinterPrintModeDoubleWide   = 1 << 5,
    ESCPrinterPrintModeUnderline    = 1 << 7
};

typedef NS_ENUM(uint8_t, ESCPrinterCharacterSet) {
    ESCPrinterCharacterSetAmerica,
    ESCPrinterCharacterSetFrance,
    ESCPrinterCharacterSetGermany,
    ESCPrinterCharacterSetUK
};

@protocol ESCPrinterDelegate;

@interface ESCPrinter : NSObject <NSStreamDelegate>
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

@property (nonatomic, assign) id<ESCPrinterDelegate> delegate;

+ (ESCPrinter *)initSharedPrinterWithHost:(NSString *)host port:(NSInteger)port;
+ (ESCPrinter *)sharedPrinter;
- (void)feed;
- (void)feedLines:(uint8_t)lines;
- (void)cut;
- (void)text:(NSString *)text;
#if TARGET_OS_IPHONE
- (void)image:(UIImage *)image;
#else
- (void)image:(NSImage *)image;
#endif
- (void)setAlignment:(ESCPrinterAlignment)alignment;
- (void)setCharacterSet:(ESCPrinterCharacterSet)set;
- (void)setPrintMode:(ESCPrinterPrintMode)mode;
- (void)setLineSpacing:(uint8_t)spacing;
- (void)setTabPositions:(NSArray *)positions;
- (void)openCashDrawer;

@end

@protocol ESCPrinterDelegate <NSObject>

@optional
- (void)printer:(ESCPrinter *)printer paperOut:(BOOL)paperOut nearEnd:(BOOL)nearEnd;
- (void)printer:(ESCPrinter *)printer coverOpen:(BOOL)coverOpen;
- (void)printer:(ESCPrinter *)printer drawerOpen:(BOOL)drawerOpen;

@end
