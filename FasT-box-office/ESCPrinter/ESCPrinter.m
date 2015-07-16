//
//  ESCPrinter.m
//  PrinterTest
//
//  Created by Albrecht Oster on 15.01.14.
//  Copyright (c) 2014 Albisigns. All rights reserved.
//

#import "ESCPrinter.h"

@interface ESCPrinter ()
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

- (id)initWithHost:(NSString *)hostname port:(NSInteger)p;
- (void)connectionTimedOut;
- (void)handleInputStreamEvent:(NSStreamEvent)event;
- (void)handleOutputStreamEvent:(NSStreamEvent)event;
- (void)prepareDataFromString:(char *)string length:(NSInteger)length;
- (void)prepareDataFromString:(char *)string length:(NSInteger)length lastByte:(uint8_t)lastByte;
- (void)sendData:(NSData *)data;
- (void)send;
- (void)closeStreams;
- (void)releaseStreams;
- (void)setupPrinter;
- (void)toggleASB:(BOOL)toggle;
- (void)parseStatusFromData:(uint8_t[])data length:(NSInteger)length;
- (void)sendHeartbeat;
- (void)cancelAllTimers;

@end

@implementation ESCPrinter

static ESCPrinter *sharedESCPrinter = nil;

+ (ESCPrinter *)sharedPrinter
{
    return sharedESCPrinter;
}

+ (ESCPrinter *)initSharedPrinterWithHost:(NSString *)hostname port:(NSInteger)p
{
    [self nillify];
    sharedESCPrinter = [[super alloc] initWithHost:hostname port:p];
    return sharedESCPrinter;
}

+ (void)nillify
{
    [sharedESCPrinter release];
    sharedESCPrinter = nil;
}

+ (BOOL)isPresent
{
    return !!sharedESCPrinter;
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
        coverOpened = NO;
        drawerOpened = NO;
        paperOut = NO;
        paperNearEnd = NO;
        
        host = CFHostCreateWithName(NULL, (CFStringRef)hostname);
        port = p;
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
    [self releaseStreams];
    CFRelease(host);
    [outputData release];
    [super dealloc];
}

#pragma methods

- (void)connect
{
    spaceAvailable = NO;
    dataIndex = 0;
    connected = NO;
    
    [self cancelAllTimers];
    [self performSelector:@selector(connectionTimedOut) withObject:self afterDelay:2];
    
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

- (void)disconnect
{
    [self closeStreams];
}

- (void)connectionTimedOut
{
    [self handleOutputStreamEvent:NSStreamEventErrorOccurred];
}

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
    NSData *data = [text dataUsingEncoding:NSWindowsCP1252StringEncoding];
    [self sendData:data];
}

#if TARGET_OS_IPHONE
- (void)image:(UIImage *)image
#else
- (void)image:(NSImage *)image
#endif
{
    [self image:image threshold:120];
}

#if TARGET_OS_IPHONE
- (void)image:(UIImage *)image threshold:(uint8_t)threshold
#else
- (void)image:(NSImage *)image threshold:(uint8_t)threshold
#endif
{
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

- (void)horizontalLine:(BOOL)doubleLine
{
    NSInteger width = 56;
    char line[width+2];
    line[0] = line[width+1] = '\n';
    for (NSInteger i = 1; i < width+1; i++) {
        line[i] = doubleLine ? '=' : '-';
    }
    [self setFont:ESCPrinterFontB adjustLineSpacing:YES];
    [self prepareDataFromString:line length:width+2];
    [self setFont:ESCPrinterFontA adjustLineSpacing:YES];
}

- (void)setAlignment:(ESCPrinterAlignment)alignment
{
    [self prepareDataFromString:"\x1b\x61" length:2 lastByte:alignment];
}

- (void)setFont:(ESCPrinterFont)font
{
    [self setFont:font adjustLineSpacing:YES];
}

- (void)setFont:(ESCPrinterFont)font adjustLineSpacing:(BOOL)adjust
{
    uint8_t spacing[2] = {80, 55};
    if (adjust) [self setLineSpacing:spacing[font]];
    [self prepareDataFromString:"\x1b\x4d" length:2 lastByte:font];
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

- (void)setAbsolutePosition:(uint16_t)position
{
    char data[4] = "\x1b\x24";
    data[2] = position & 0xff;
    data[3] = (position >> 8) & 0xff;
    [self prepareDataFromString:data length:4];
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
    [self prepareDataFromString:"\x1b\x74\x10" length:3];
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
        if ([_delegate respondsToSelector:@selector(printer:coverOpen:)]) {
            [_delegate printer:self coverOpen:state];
        }
        NSLog(@"Cover opened: %d", state);
    }
    
    state = ((*status)[2] & 0x4) >> 2;
    state2 = (*status)[2] & 0x1;
    if (state != paperOut || state2 != paperNearEnd) {
        paperOut = state;
        paperNearEnd = state2;
        if ([_delegate respondsToSelector:@selector(printer:paperOut:nearEnd:)]) {
            [_delegate printer:self paperOut:state nearEnd:state2];
        }
        NSLog(@"paper out: %d, near end: %d", state, state2);
    }
    
    state = !(((*status)[0] & 0x4) >> 2);
    if (state != drawerOpened) {
        drawerOpened = state;
        if ([_delegate respondsToSelector:@selector(printer:drawerOpen:)]) {
            [_delegate printer:self drawerOpen:state];
        }
        NSLog(@"drawer open: %d", state);
    }
}

- (void)openCashDrawer
{
    [self prepareDataFromString:"\x1b\x70\x0\x32\x32" length:5];
}

#pragma mark private methods

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
            [self cancelAllTimers];
            connected = YES;
            [self sendHeartbeat];
            [self setupPrinter];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            [self send];
            break;
            
        case NSStreamEventErrorOccurred:
            [self closeStreams];
            [self performSelector:@selector(connect) withObject:nil afterDelay:2];
            break;
            
        default:
            break;
    }
}

- (void)prepareDataFromString:(char *)string length:(NSInteger)length
{
    [self sendData:[NSData dataWithBytes:string length:length]];
}

- (void)sendData:(NSData *)data
{
    if (!connected) return;
    if (!outputData) {
        if ([data isKindOfClass:[NSMutableData class]]) {
            outputData = [(NSMutableData*)data retain];
        } else {
            outputData = [data mutableCopy];
        }
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
    [self cancelAllTimers];
    connected = NO;
    [input close];
    [output close];
}

- (void)releaseStreams
{
    [input release];
    [output release];
}

- (void)sendHeartbeat
{
    char heartbeat = 0;
    [self sendData:[NSData dataWithBytes:&heartbeat length:1]];
    [self performSelector:@selector(sendHeartbeat) withObject:self afterDelay:3];
}

- (void)cancelAllTimers
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
