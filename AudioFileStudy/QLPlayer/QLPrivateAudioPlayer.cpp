//
//  QLPrivateAudioPlayer.cpp
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/26.
//  Copyright © 2016年 Debugly. All rights reserved.
//
//底层私有的音乐播放器
#include "QLPrivateAudioPlayer.hpp"
#include "QLAudioDebugMacros.h"

static void QLReadToBufferCallback(void *               inUserData,
                                   AudioQueueRef        inAQ,
                                   AudioQueueBufferRef  inCompleteAQBuffer)
{
    QLAudioFileInfo * myInfo = (QLAudioFileInfo *)inUserData;
    if (myInfo->mDone) return;
    
    UInt32 numBytes;
    UInt32 nPackets = myInfo->mNumOfPacketsRead;
    
    OSStatus error = AudioFileReadPackets(myInfo->mAudioFileID,
                                          false,
                                          &numBytes,
                                          myInfo->mPacketDesc,
                                          myInfo->mCurrentPacket,
                                          &nPackets,
                                          inCompleteAQBuffer->mAudioData);
    if (error) {
        QLAudioDebugMsgN1("read packets error:%d\n",error);
    }
    
    if (nPackets > 0) {
        inCompleteAQBuffer->mAudioDataByteSize = numBytes;
        
        error = AudioQueueEnqueueBuffer(inAQ,
                                        inCompleteAQBuffer,
                                        (myInfo->mPacketDesc ? nPackets : 0),
                                        myInfo->mPacketDesc);
        if (error) {
            return;
        }
        
        myInfo->mCurrentPacket += nPackets;
        
        QLAudioDebugMsgN2("read packet:%d-currentPacket:%lld", nPackets, myInfo->mCurrentPacket);
        
    }else{
        myInfo->mDone = true;
    }
}

static void CalculateBytesForTime(AudioStreamBasicDescription & inDesc, UInt32 inMaxPacketSize, Float64 inSeconds, UInt32 * outBufferSize, UInt32 *outNumPackets)
{
    static const int maxBufferSize = 0x10000;//2(16) = 64K;
    static const int minBufferSize = 0x4000;//4x2(12)= 16k;
    
    if (inDesc.mFramesPerPacket) {
        //        float sum = 238 * inDesc.mSampleRate / inDesc.mFramesPerPacket;
        Float64 numPacketsFoTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
        *outBufferSize = numPacketsFoTime * inMaxPacketSize;
    }else{
        *outBufferSize = maxBufferSize > inMaxPacketSize ? maxBufferSize : inMaxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > inMaxPacketSize) {
        *outBufferSize = maxBufferSize;
    }else{
        if (*outBufferSize < minBufferSize) {
            *outBufferSize = minBufferSize;
        }
    }
    *outNumPackets = *outBufferSize / inMaxPacketSize;
}

QLPrivateAudioPlayer::QLPrivateAudioPlayer()
{
    
}

QLPrivateAudioPlayer::QLPrivateAudioPlayer(const char *fp)
{
    size_t fplen = 0;
    if ((fplen = strlen(fp))) {
        char *str = (char *)malloc(fplen);
        strcpy(str, fp);
        this->filePath = str;
    }
    this->_volume = 0.5;
}

void QLPrivateAudioPlayer::readFile()
{
    if (!this->filePath) {
        QLAudioDebugMsg("file path is nil");
        return;
    }
    
    CFURLRef sndFile = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)this->filePath, strlen(this->filePath), false);
    if (!sndFile) {
        QLAudioDebugMsg("can't parse file path");
    }
    
    OSStatus error = AudioFileOpenURL(sndFile, kAudioFileReadPermission, 0, &this->audioFileInfo.mAudioFileID);
    CFRelease(sndFile);
    
    if (error) {
        QLAudioDebugMsg("audioFile Open failed");
    }
    
    UInt32 size;
    size = sizeof(this->audioFileInfo.mPacketCount);
    if (AudioFileGetProperty(this->audioFileInfo.mAudioFileID, kAudioFilePropertyAudioDataPacketCount, &size, &this->audioFileInfo.mPacketCount)) {
        QLAudioDebugMsg("could't get file's total packet count");
    }
    
    error = AudioFileGetPropertyInfo(this->audioFileInfo.mAudioFileID, kAudioFilePropertyFormatList, &size, NULL);
    
    if (error) {
        QLAudioDebugMsg("could't get file's data format size");
    }
    
    UInt32 numFormats = size / sizeof(AudioFormatListItem);
    AudioFormatListItem *formatList = new AudioFormatListItem[numFormats];
    
    error = AudioFileGetProperty(this->audioFileInfo.mAudioFileID, kAudioFilePropertyFormatList, &size, formatList);
    
    if (error) {
        QLAudioDebugMsg("could't get file's data format list");
    }
    
    //mybe need reassess the actual number of formats
    numFormats = size / sizeof(AudioFormatListItem);
    
    if (numFormats == 1) {
        
        this->audioFileInfo.mDataFormat = formatList[0].mASBD;
        error = AudioFileGetPropertyInfo(this->audioFileInfo.mAudioFileID, kAudioFilePropertyChannelLayout, &this->audioFileInfo.mChannelLayoutSize, NULL);
        
        if(noErr == error && this->audioFileInfo.mChannelLayoutSize > 0){
            this->audioFileInfo.mChannelLayout = (AudioChannelLayout *)new char[this->audioFileInfo.mChannelLayoutSize];
            if (noErr != AudioFileGetProperty(this->audioFileInfo.mAudioFileID, kAudioFilePropertyChannelLayout, &this->audioFileInfo.mChannelLayoutSize, this->audioFileInfo.mChannelLayout)) {
                QLAudioDebugMsg("couldn't get audio file's channel layout");
            }
        }
    }else{
        if(noErr != AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size)){
            QLAudioDebugMsg("could't get system's decode id count");
        }
        
        UInt32 numDecoders = size / sizeof(OSType);
        OSType *decoderIDs = new OSType[numDecoders];
        
        if (noErr != AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDs)) {
            QLAudioDebugMsg("could't get system's decode ids");
        }
        
        unsigned int i = 0;
        for (; i < numFormats; i++) {
            OSType decoderID = formatList[i].mASBD.mFormatID;
            bool found = false;
            for (int j = 0; j < numDecoders; j++) {
                if (decoderID == decoderIDs[j]) {
                    found = true;
                    break;
                }
            }
            if (found) break;
        }
        delete [] decoderIDs;
        
        if (i >= numFormats) {
            QLAudioDebugMsg("Can't play this file,none format matched");
            throw kAudioFileUnsupportedDataFormatError;
        }
        
        this->audioFileInfo.mDataFormat = formatList[i].mASBD;
        this->audioFileInfo.mChannelLayoutSize = sizeof(AudioChannelLayout);
        this->audioFileInfo.mChannelLayout = (AudioChannelLayout *)new char[this->audioFileInfo.mChannelLayoutSize];
        this->audioFileInfo.mChannelLayout->mChannelLayoutTag = formatList[i].mChannelLayoutTag;
        this->audioFileInfo.mChannelLayout->mChannelBitmap = 0;
        this->audioFileInfo.mChannelLayout->mNumberChannelDescriptions = 0;
    }
    delete [] formatList;
}

void QLPrivateAudioPlayer::createAudioQueue()
{
    UInt32 size;
    //when success,return an audio queue;
    if (noErr != AudioQueueNewOutput(&this->audioFileInfo.mDataFormat, QLReadToBufferCallback, &this->audioFileInfo, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &this->audioFileInfo.mQueue)) {
        QLAudioDebugMsg("couldn't create audio queue");
    }
    
    //check cookie,if the file has a cookie,wo should get it then set it on the AudioQueue.
    size = sizeof(UInt32);
    if (noErr != AudioFileGetPropertyInfo(this->audioFileInfo.mAudioFileID, kAudioFilePropertyMagicCookieData, &size, NULL)) {
        QLAudioDebugMsg("read cookie size failed");
    }
    
    if (size > 0) {
        char * cookie = new char[size];
        if (noErr == AudioFileGetProperty(this->audioFileInfo.mAudioFileID, kAudioFilePropertyMagicCookieData, &size, cookie)) {
            if(AudioQueueSetProperty(this->audioFileInfo.mQueue, kAudioFilePropertyMagicCookieData, cookie, size)){
                QLAudioDebugMsg("set cookie on queue failed");
            }
        }else{
            QLAudioDebugMsg("read cookie data failed");
        }
        delete [] cookie;
    }
    
    //set ACL
    if (this->audioFileInfo.mChannelLayout) {
        if (AudioQueueSetProperty(this->audioFileInfo.mQueue, kAudioQueueProperty_ChannelLayout, this->audioFileInfo.mChannelLayout, this->audioFileInfo.mChannelLayoutSize)) {
            QLAudioDebugMsg("set channel layout on queue failed");
        }
    }
}

void QLPrivateAudioPlayer::resetVolume(float v)
{
    if (this->_volume != v) {
        this->_volume = v;
        
        AudioQueueRef queue = this->audioFileInfo.mQueue;
        if (queue) {
            AudioQueueSetParameter(queue, kAudioQueueParam_Volume, v);
        }
    }
}

void QLPrivateAudioPlayer::seekTo(float p)
{
    AudioQueuePause(this->audioFileInfo.mQueue);
    AudioQueueReset(this->audioFileInfo.mQueue);
    UInt64 totalCount = this->audioFileInfo.mPacketCount;
    this->audioFileInfo.mCurrentPacket = totalCount * p;
    AudioQueueRef queue = this->audioFileInfo.mQueue;
    for (int i = 0; i < kNumberOfBuffers; i++) {
        
        QLReadToBufferCallback(&this->audioFileInfo, queue, this->audioFileInfo.mBuffers[i]);
        
        if (this->audioFileInfo.mDone) {
            break;
        }
    }
    AudioQueueStart(this->audioFileInfo.mQueue, NULL);
}

void QLPrivateAudioPlayer::preparePlay()
{
    this->readFile();
    this->createAudioQueue();
    this->audioFileInfo.mDone = false;
    this->audioFileInfo.mCurrentPacket = 0;
    
    //calculate how many packets we read at a time,and how big a buffer we need
    UInt32 bufferByteSize;
    {
        //base this on the size of the packets in the file and an approximate dutation for each buffer
        bool isFormatVBR = (this->audioFileInfo.mDataFormat.mBytesPerPacket == 0 || this->audioFileInfo.mDataFormat.mFramesPerPacket == 0);
        
        UInt32 maxPacketSize;
        UInt32 size;
        
        size = sizeof(maxPacketSize);
        if (noErr != AudioFileGetProperty(this->audioFileInfo.mAudioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxPacketSize)) {
            QLAudioDebugMsg("couldn't get file's max packet size");
        }
        
        //adjust buffer size to represent about a half second of audio based on this format
        CalculateBytesForTime(this->audioFileInfo.mDataFormat, maxPacketSize, 0.5, &bufferByteSize, &this->audioFileInfo.mNumOfPacketsRead);
        
        if (isFormatVBR) {
            this->audioFileInfo.mPacketDesc = new AudioStreamPacketDescription[this->audioFileInfo.mNumOfPacketsRead];
        }else{
            this->audioFileInfo.mPacketDesc = NULL;//constant bit rate formats, like linear PCM;
        }
    }
    
    AudioQueueRef queue = this->audioFileInfo.mQueue;
    for (int i = 0; i < kNumberOfBuffers; i++) {
        if (noErr != AudioQueueAllocateBuffer(queue, bufferByteSize, &this->audioFileInfo.mBuffers[i])) {
            QLAudioDebugMsg("audio queue alloc buffer failed");
        }
        QLReadToBufferCallback(&this->audioFileInfo, queue, this->audioFileInfo.mBuffers[i]);
        
        if (this->audioFileInfo.mDone) {
            break;
        }
    }
}

void QLPrivateAudioPlayer::play()
{
    if (this->audioFileInfo.mDone) {
        //如果播放结束了，就重置；
        this->preparePlay();
    }
    if(AudioQueueStart(this->audioFileInfo.mQueue, NULL)){
        QLAudioDebugMsg("start play failed");
    }else{
        QLAudioDebugMsg("start play success");
    }
}

void QLPrivateAudioPlayer::pause()
{
    AudioQueuePause(this->audioFileInfo.mQueue);
}

void QLPrivateAudioPlayer::stop()
{
    AudioQueueDispose(this->audioFileInfo.mQueue, true);
    AudioFileClose(this->audioFileInfo.mAudioFileID);
    //clean;
}

double QLPrivateAudioPlayer::playedProgress()
{
    //    AudioTimeStamp timestamp;
    //    if (noErr == AudioQueueGetCurrentTime(this->audioFileInfo.mQueue, NULL, &timestamp, NULL)) {
    //        double ctime = timestamp.mSampleTime / this->audioFileInfo.mDataFormat.mSampleRate;
    //        return ctime;
    //    }
    //    return 0.0;
    return 1.0 * this->audioFileInfo.mCurrentPacket / this->audioFileInfo.mPacketCount;
}
