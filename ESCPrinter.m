//
//  ESCPrinter.m
//  PrinterTest
//
//  Created by Albrecht Oster on 15.01.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "ESCPrinter.h"

@interface ESCPrinter ()

- (id)initWithHost:(NSString *)hostname port:(NSInteger)p;
- (void)handleInputStreamEvent:(NSStreamEvent)event;
- (void)handleOutputStreamEvent:(NSStreamEvent)event;
- (void)prepareDataFromString:(char *)string length:(NSInteger)length;
- (void)prepareDataFromString:(char *)string length:(NSInteger)length lastByte:(uint8_t)lastByte;
- (void)sendData:(NSMutableData *)data;
- (void)send;
- (void)connect;
- (void)closeStreams;
- (void)releaseStreams;
- (void)setupPrinter;
- (void)toggleASB:(BOOL)toggle;
- (void)parseStatusFromData:(uint8_t[])data length:(NSInteger)length;

@end

@implementation ESCPrinter

static ESCPrinter *sharedESCPrinter = nil;

+ (ESCPrinter *)sharedPrinter
{
    return sharedESCPrinter;
}

+ (ESCPrinter *)initSharedPrinterWithHost:(NSString *)hostname port:(NSInteger)p
{
    [sharedESCPrinter release];
    sharedESCPrinter = [[super alloc] initWithHost:hostname port:p];
    return sharedESCPrinter;
}

- (id)init
{
    [NSException raise:@"ESCPrinterNotInitiatedException" format:@"An ESC printer has to be initiated by sending initSharedPrinterWithHost:port: first."];
    return nil;
}

- (id)initWithHost:(NSString *)hostname port:(NSInteger)p
{
    self = [super init];
    if (self) {
        spaceAvailable = NO;
        dataIndex = 0;
        connected = NO;
        coverOpened = NO;
        drawerOpened = NO;
        paperOut = NO;
        paperNearEnd = NO;
        
        host = CFHostCreateWithName(NULL, (CFStringRef)hostname);
        port = p;
        [self connect];
    }
    return self;
}

- (void)dealloc
{
    [self closeStreams];
    [self releaseStreams];
    CFRelease(host);
    [outputData release];
    [super dealloc];
}

#pragma methods

- (void)feed
{
    [self prepareDataFromString:"\n" length:1];
}

- (void)feedLines:(uint8_t)lines
{
    [self prepareDataFromString:"\x1b\x64" length:2 lastByte:(uint8_t)lines];
}

- (void)cut
{
    uint8_t currentSpacing = lineSpacing;
    [self setLineSpacing:30];
    [self feedLines:10];
    [self prepareDataFromString:"\x1d\x56\x00" length:3];
    [self setLineSpacing:currentSpacing];
}

- (void)text:(NSString *)text
{
    [self sendData:[[[text dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease]];
}

#if TARGET_OS_IPHONE
- (void)image:(UIImage *)image
#else
- (void)image:(NSImage *)image
#endif
{
    uint8_t threshold = 150;
    
    NSUInteger width = image.size.width;
    NSUInteger height = image.size.height;
    if (width <= 0 || height <= 0) return;
    
    uint8_t imageData[width*height];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(&imageData, width, height, 8, width, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    CGRect rect = CGRectMake(0, 0, width, height);
#if TARGET_OS_IPHONE
    CGImageRef maskImage = [image CGImage];
#else
    CGImageRef maskImage = [image CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil];
#endif
    CGContextDrawImage(context, rect, maskImage);
    
    NSMutableData *sendData = [NSMutableData dataWithBytes:"\x1b\x33\x18" length:3];
    
    for (int totalHeight = 0; totalHeight < height; totalHeight += 24) {
        uint8_t dotData[3*width];
        
        for (int w = 0; w < width; w++) {
            for (int d = 0; d < 3; d++) {
                uint8_t dotByte = 0;
                int byteOffset = totalHeight + d * 8;
                for (int h = 0; h < 8; h++) {
                    if (h > 0) dotByte = dotByte << 1;
                    size_t pixel = (byteOffset + h) * width + w;
                    if (pixel < sizeof(imageData)) {
                        dotByte += (uint8_t)(imageData[pixel] < threshold);
                    }
                }
                dotData[w*3+d] = dotByte;
            }
        }
        
        [sendData appendBytes:"\x1b\x2a\x21" length:3];
        uint16_t dotWidth = width;
        [sendData appendBytes:&dotWidth length:2];
        [sendData appendBytes:&dotData length:3*width];
        [sendData appendBytes:"\n" length:1];
    }
    
    [sendData appendBytes:"\x1b\x33\x1e" length:3];
    [self sendData:sendData];
    
    CGContextRelease(context);
}

- (void)setAlignment:(ESCPrinterAlignment)alignment
{
    [self prepareDataFromString:"\x1b\x61" length:2 lastByte:alignment];
}

- (void)setPrintMode:(ESCPrinterPrintMode)mode
{
    [self prepareDataFromString:"\x1b\x21" length:2 lastByte:mode];
}

- (void)setCharacterSet:(ESCPrinterCharacterSet)set
{
    [self prepareDataFromString:"\x1b\x52" length:2 lastByte:set];
}

- (void)setLineSpacing:(uint8_t)spacing
{
    lineSpacing = spacing;
    [self prepareDataFromString:"\x1b\x33" length:2 lastByte:spacing];
}

- (void)setTabPositions:(NSArray *)positions
{
    [self prepareDataFromString:"\x1b\x44" length:2];
    for (NSNumber *pos in positions) {
        char data[1] = { [pos integerValue] };
        [self prepareDataFromString:data length:1];
    }
    [self prepareDataFromString:"\x00" length:1];
}

- (void)setupPrinter
{
    [self toggleASB:YES];
}

- (void)toggleASB:(BOOL)toggle
{
    [self prepareDataFromString:"\x1d\x61" length:2 lastByte:(toggle) ? 0xff : 0];
}

- (void)parseStatusFromData:(uint8_t[])data length:(NSInteger)length
{
    uint8_t (*status)[4] = (uint8_t(*)[4])data + ((length / 4 - 1) * 4);
    
    BOOL state = ((*status)[0] & 0x20) >> 5, state2;
    if (state != coverOpened) {
        coverOpened = state;
        [_delegate printer:self coverOpen:state];
        NSLog(@"Cover opened: %d", state);
    }
    
    state = ((*status)[2] & 0x4) >> 2;
    state2 = (*status)[2] & 0x1;
    if (state != paperOut || state2 != paperNearEnd) {
        paperOut = state;
        paperNearEnd = state2;
        [_delegate printer:self paperOut:state nearEnd:state2];
        NSLog(@"paper out: %d, near end: %d", state, state2);
    }
    
    state = !(((*status)[0] & 0x4) >> 2);
    if (state != drawerOpened) {
        drawerOpened = state;
        [_delegate printer:self drawerOpen:state];
        NSLog(@"drawer open: %d", state);
    }
}

- (void)openCashDrawer
{
    [self prepareDataFromString:"\x1b\x70\x0\x32\x32" length:5];
}

#pragma mark private methods

- (void)connect
{
    CFReadStreamRef read;
    CFWriteStreamRef write;
    CFStreamCreatePairWithSocketToCFHost(NULL, host, (int)port, &read, &write);
    [self releaseStreams];
    input = (NSInputStream *)read;
    output = (NSOutputStream *)write;
    for (NSStream *stream in @[input, output]) {
        [stream setDelegate:self];
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
    }
}

- (void)handleInputStreamEvent:(NSStreamEvent)event
{
    switch (event) {
        case NSStreamEventHasBytesAvailable: {
            uint8_t data[8], bytesRead;
            
            bytesRead = [input read:data maxLength:8];
            if (bytesRead) {
                [self parseStatusFromData:data length:bytesRead];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)handleOutputStreamEvent:(NSStreamEvent)event
{
    switch (event) {
        case NSStreamEventOpenCompleted:
            connected = YES;
            [self setupPrinter];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            [self send];
            break;
            
        case NSStreamEventErrorOccurred:
            [self closeStreams];
            if (connected) {
                [self connect];
            } else {
                NSLog(@"cannot connect to printer");
            }
            connected = NO;
            break;
            
        default:
            break;
    }
}

- (void)prepareDataFromString:(char *)string length:(NSInteger)length
{
    [self sendData:[NSMutableData dataWithBytes:string length:length]];
}

- (void)sendData:(NSMutableData *)data
{
    if (!outputData) {
        outputData = [data retain];
    } else {
        [outputData appendData:data];
    }
    if (spaceAvailable) {
        [self send];
    }
}

- (void)prepareDataFromString:(char *)string length:(NSInteger)length lastByte:(uint8_t)lastByte
{
    char data[length+1];
    strcpy(data, string);
    data[length] = lastByte;
    [self prepareDataFromString:data length:length+1];
}

- (void)send
{
    if (outputData && dataIndex < [outputData length]) {
        uint8_t *readBytes = (uint8_t *)[outputData bytes];
        readBytes += dataIndex;
        NSUInteger length = [outputData length] - dataIndex;
        length = [output write:readBytes maxLength:length];
        dataIndex += length;
        spaceAvailable = NO;
    } else {
        dataIndex = 0;
        [outputData release];
        outputData = nil;
        spaceAvailable = YES;
    }
}

- (void)closeStreams
{
    [input close];
    [output close];
}

- (void)releaseStreams
{
    [input release];
    [output release];
}

#pragma mark stream delegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    if (stream == input) {
        [self handleInputStreamEvent:event];
    } else if (stream == output) {
        [self handleOutputStreamEvent:event];
    }
}

@end
