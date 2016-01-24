//
//  QLAudioFile.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/22.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "QLAudioFile.h"
#import <AudioToolbox/AudioToolbox.h>

@interface QLAudioFile ()
{
@private
    unsigned long long _fileSize;
    AudioFileID _audioFileID;
    SInt64 _dataOffset;
}
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) AudioFileTypeID fileType;
@property (nonatomic, strong) NSFileHandle  *fileHandler;
@property (nonatomic,assign,readwrite) AudioStreamBasicDescription format;
@property (nonatomic,assign,readwrite) UInt32 bitRate;
@property (nonatomic,assign,readwrite) UInt64 audioDataByteCount;
@property (nonatomic,assign,readwrite) NSTimeInterval duration;
@property (nonatomic,assign,readwrite) UInt32 maxPacketSize;

@end

@implementation QLAudioFile

- (instancetype)initWithFilePath:(NSString *)filePath fileType:(AudioFileTypeID)fileType
{
    self = [super init];
    if (self) {
        self.filePath = filePath;
        self.fileType = fileType;
        _fileSize = [[[NSFileManager defaultManager]attributesOfItemAtPath:filePath error:nil]fileSize];
        if (_fileSize > 0) {
            self.fileHandler = [NSFileHandle fileHandleForReadingAtPath:filePath];
            if (!self.fileHandler) {
                return nil;
            }else{
                if ([self _openAudioFile]) {
                    [self _fetchAudioFileFormatInfo];
                }
            }
        }else{
            return nil;
        }
    }
    return self;
}

#pragma mark - utils read data

- (UInt32)availableDataLengthAtOffset:(SInt64)inPosition maxLength:(UInt32)requestCount
{
    SInt64 maxLength = inPosition + requestCount;
    if ((inPosition > _fileSize) || (maxLength > _fileSize)) {
        return 0;
    }
    return (UInt32)MIN(requestCount, _fileSize-inPosition);
}

- (NSData *)dataOfRange:(NSRange)range
{
    [self.fileHandler seekToFileOffset:range.location];
    return [self.fileHandler readDataOfLength:range.length];
}

#pragma mark - read CallBack

static OSStatus QLAudioFile_ReadFunc(
                                     void *		inClientData,
                                     SInt64		inPosition,
                                     UInt32		requestCount,
                                     void *		buffer,
                                     UInt32 *	actualCount)
{
    QLAudioFile *audioFile = (__bridge QLAudioFile *)inClientData;
    UInt32 resultCount = [audioFile availableDataLengthAtOffset:inPosition maxLength:requestCount];
    *actualCount = requestCount;
    
    if (resultCount > 0) {
        NSData *data = [audioFile dataOfRange:NSMakeRange(inPosition, resultCount)];
        memcpy(buffer, [data bytes], resultCount);
    }
    return noErr;
}

static SInt64 QLAudioFile_GetSizeFunc(
                                      void * 		inClientData)
{
    QLAudioFile *audioFile = (__bridge QLAudioFile *)inClientData;
    return audioFile->_fileSize;
}

- (BOOL)_openAudioFile
{
    OSStatus status = AudioFileOpenWithCallbacks((__bridge void *)self,
                                                 QLAudioFile_ReadFunc,
                                                 NULL,
                                                 QLAudioFile_GetSizeFunc,
                                                 NULL,
                                                 _fileType,
                                                 &_audioFileID);
    if (noErr != status) {
        _audioFileID = NULL;
        return NO;
    }
    return YES;
}

- (void)_closeAudioFile
{
    if ([self available]) {
        AudioFileClose(_audioFileID);
        _audioFileID = NULL;
    }
}

- (BOOL)available
{
    return _audioFileID != NULL;
}

- (void)_calculatePacketDuration
{
    
}

- (void)_fetchAudioFileFormatInfo
{
    if (![self available]) {
        return;
    }
    //read format;
    {
        UInt32 formatListSize;
        //先获取格式列表大小；
        OSStatus status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyFormatList, &formatListSize, NULL);
        if (noErr == status) {
            BOOL found = NO;
            //根据获取的列表的大小申请内存空间；
            AudioFormatListItem *formatList = (AudioFormatListItem *)malloc(formatListSize);
            //获取格式列表到分配的空间
            OSStatus status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyFormatList, &formatListSize, formatList);
            if (noErr == status) {
                UInt32 supportedFormatsSize;
                //获取解码格式ID列表大小
                status = AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize);
                if (noErr != status) {
                    free(formatList);
                    formatList = NULL;
                    [self _closeAudioFile];
                    return;
                }
                //计算出支持几个格式；
                UInt32 supportedFormatCount = supportedFormatsSize / sizeof(OSType);
                //分配内存空间；
                OSType *supportedFormats = (OSType *)malloc(supportedFormatsSize);
                //获取格式ID到分配的空间
                status = AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &supportedFormatsSize, supportedFormats);
                if (noErr != status) {
                    free(formatList);
                    formatList = NULL;
                    [self _closeAudioFile];
                    return;
                }
                //遍历格式列表，找到正确的格式
                for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem)) {
                    AudioStreamBasicDescription format = formatList[i].mASBD;
                    for (UInt32 j = 0; j < supportedFormatCount; j++) {
                        if (format.mFormatID == supportedFormats[j]) {
                            self.format = format;
                            found = YES;
                            break;
                        }
                    }
                }
                free(supportedFormats);
            }
            free(formatList);
            
            if (!found) {
                [self _closeAudioFile];
                return;
            }else{
                [self _calculatePacketDuration];
            }
        }
    }
    //read bitrate;
    UInt32 size = sizeof(_bitRate);
    OSStatus status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyBitRate, &size, &_bitRate);
    if (noErr != status) {
        [self _closeAudioFile];
        return;
    }
    
    //read dataOffset;
    size = sizeof(_dataOffset);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataOffset, &size, &_dataOffset);
    if (noErr != status) {
        [self _closeAudioFile];
        return;
    }
    
    //calute audio data byte count;
    _audioDataByteCount = _fileSize - _dataOffset;
    
    //read duration;
    size = sizeof(_duration);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyEstimatedDuration, &size, &_duration);
    if (noErr != status) {
        [self _closeAudioFile];
        return;
    }
    
    //read max packer size;
    size = sizeof(_maxPacketSize);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &_maxPacketSize);
    if (noErr != status || 0 == _maxPacketSize) {
        status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyMaximumPacketSize, &size, &_maxPacketSize);
        if (status != noErr)
        {
            [self _closeAudioFile];
            return;
        }
    }
    
    //read info;
    status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyInfoDictionary, &size, 0);
    if (noErr == status) {
        CFDictionaryRef infoDictRef;
        status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyInfoDictionary, &size, &infoDictRef);
        NSDictionary *infoDict = (__bridge_transfer NSDictionary *)infoDictRef;
        NSLog(@"---%@",infoDict);
        /*
        album = "\U50cf\U68a6\U4e00\U6837\U81ea\U7531";
        "approximate duration in seconds" = "238.132";
        artist = "\U6c6a\U5cf0";
        comments = "ting.baidu.com";
        title = "\U50cf\U68a6\U4e00\U6837\U81ea\U7531";
        year = "2011-03-22";
         */
    }
}

- (NSData *)readAlbumImageData
{
    UInt32 imageSize;
    OSStatus status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyAlbumArtwork, &imageSize, NULL);
    if (noErr == status) {
        CFDataRef dataRef = CFDataCreate(NULL, nil, imageSize);//malloc(imageSize);
        AudioFileGetProperty(_audioFileID, kAudioFilePropertyAlbumArtwork, &imageSize, &dataRef);
        return (__bridge_transfer NSData *)dataRef;
    }else{
        UInt32 id3TagPropertySize;
        status = AudioFileGetPropertyInfo(_audioFileID, kAudioFilePropertyID3Tag, &id3TagPropertySize, NULL);
        if (noErr == status) {
            char *rawID3Tag = (char *)malloc(id3TagPropertySize);
            status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyID3Tag, &id3TagPropertySize, rawID3Tag);
            if (noErr != status) {
                free(rawID3Tag);
                return nil;
            }else{
                UInt32 id3TagSize;
                UInt32 id3TagSizeLength = sizeof(id3TagSize);
                status = AudioFormatGetProperty(kAudioFormatProperty_ID3TagSize, id3TagPropertySize, rawID3Tag, &id3TagSizeLength, &id3TagSize);
                if (noErr != status) {
                    free(rawID3Tag);
                    return nil;
                }
                CFDictionaryRef id3Dict;
                status = AudioFormatGetProperty(kAudioFormatProperty_ID3TagToDictionary, id3TagPropertySize, rawID3Tag, &id3TagSize, &id3Dict);
                
                free(rawID3Tag);
                
                if (noErr != status) {
                    return nil;
                }
                NSDictionary *tagDict = (__bridge_transfer NSDictionary *)id3Dict;
                NSDictionary *apicDict = tagDict[@"APIC"];
                /*
                 COMM =     {
                 a =         {
                 identifier = a;
                 language = eng;
                 text = "ting.baidu.com";
                 };
                 };
                 TALB = "像梦一样自由";
                 TIT2 = "像梦一样自由";
                 TPE1 = "汪峰";
                 TXXX =     {
                 "\UfeffTagging time" =         {
                 identifier = "\UfeffTagging time";
                 text = "2011-12-07T10:51:04";
                 };
                 };
                 TYER = "2011-03-22";
                 */
                if (!apicDict) return nil;
                
                NSString *picKey      = [[apicDict allKeys] lastObject];
                NSDictionary *picDict = apicDict[picKey];
                if (!picDict) return nil;
                
                return picDict[@"data"];//MIME = "image/jpeg";identifier = e;picturetype = "Cover (front)";
            }
        }
    }
    return nil;
}

- (NSString *)description
{
    NSMutableString *mulStr = [[NSMutableString alloc]init];
    [mulStr appendString:@"\n--------------audio info begin-------------\n"];
    [mulStr appendFormat:@"|-bitRate:%d -dataOffset:%lld -dutation:%f -maxPacketSize:%d\n",_bitRate,_dataOffset,_duration,_maxPacketSize];
    [mulStr appendFormat:@"|-formatID:%d\n",_format.mFormatID];
    [mulStr appendFormat:@"|-sampleRate:%f\n",_format.mSampleRate];
    [mulStr appendFormat:@"|-mBytesPerPacket:%u\n",_format.mBytesPerPacket];
    [mulStr appendFormat:@"|-mFramesPerPacket:%u\n",_format.mFramesPerPacket];
    [mulStr appendFormat:@"|-mBytesPerFrame:%u\n",_format.mBytesPerFrame];
    [mulStr appendFormat:@"|-mChannelsPerFrame:%u\n",_format.mChannelsPerFrame];
    [mulStr appendFormat:@"|-mBitsPerChannel:%u\n",_format.mBitsPerChannel];
    [mulStr appendString:@"--------------audio info end---------------\n"];
    return [mulStr copy];
}

- (NSArray *)parserData:(BOOL *)isEof
{
//    UInt32 ioNumPackets = pa
    return nil;
}






















/*
 mp2,
 amr,
 ac3,
 m4r,
 adts,
 mp3,
 wav,
 3gp,
 mpa,
 mpeg,
 ec3,
 m4a,
 mp4,
 snd,
 aifc,
 caf,
 m4b,
 3g2,
 mp1,
 aac,
 aiff,
 aif,
 au
 */
+ (NSArray *)fileTypes
{
    OSStatus err;
    NSArray *sAudioExtensions;
    UInt32 size = sizeof(sAudioExtensions);
    err  = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllExtensions, 0, NULL, &size, &sAudioExtensions);
    if (noErr != err) {
        return nil;
    }
    NSLog(@"--%@",sAudioExtensions);
    return sAudioExtensions;
}

@end
