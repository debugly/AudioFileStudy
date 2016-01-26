//
//  QLAudioFile.h
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/22.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>

@interface QLAudioFile : NSObject

@property (nonatomic,assign,readonly) AudioStreamBasicDescription format;
@property (nonatomic,assign,readonly) UInt32 bitRate;
@property (nonatomic,assign,readonly) UInt64 audioDataByteCount;
@property (nonatomic,assign,readonly) NSTimeInterval duration;
@property (nonatomic,assign,readonly) UInt32 maxPacketSize;

- (instancetype)initWithFilePath:(NSString *)filePath fileType:(AudioFileTypeID)fileType;

- (NSData *)readAlbumImageData;

+ (NSArray *)audioFileExtensions;

@end
