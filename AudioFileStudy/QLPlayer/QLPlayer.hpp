//
//  QLPlayer.hpp
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/23.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#ifndef QLPlayer_hpp
#define QLPlayer_hpp

#include <stdio.h>
#include <AudioToolbox/AudioFormat.h>
#include <AudioToolbox/AudioFile.h>
#include <CoreAudio/CoreAudioTypes.h>
#include <AudioToolbox/AudioQueue.h>

static const UInt8 kNumberOfBuffers = 3;

struct QLAudioFileInfo{
    AudioFileID                     mAudioFileID;
    AudioStreamBasicDescription     mDataFormat;
    AudioChannelLayout *            mChannelLayout;
    UInt32                          mChannelLayoutSize;
    AudioQueueRef                   mQueue;
    AudioQueueBufferRef             mBuffers[kNumberOfBuffers];
    SInt64                          mCurrentPacket;
    UInt64                          mPacketCount;
    UInt32                          mNumOfPacketsRead;
    AudioStreamPacketDescription *  mPacketDesc;
    bool                            mDone;
    
    QLAudioFileInfo()
        : mChannelLayout(NULL),mPacketDesc(NULL){
        
        }
    ~QLAudioFileInfo()
    {
        delete [] mChannelLayout;
        delete [] mPacketDesc;
    }
};

typedef struct QLAudioFileInfo QLAudioFileInfo;

enum QLAudioPlayState{
    QLAudioPlayNone,
    QLAudioPlayPlaying,
    QLAudioPlayPause,
};

typedef enum QLAudioPlayState QLAudioPlayState;

class QLAudioPlayer
{
public:
    QLAudioPlayer();
    QLAudioPlayer(const char *filePath);
    
    ~QLAudioPlayer(){
        delete []filePath;
    }
    void preparePlay();
    void play();
    void pause();
    void stop();
    void resetVolume(float v);
    void seekTo(float p);
    AudioQueueParameterValue volume(){
        return _volume;
    }
    double playedProgress();
    bool isPlaying(){
        return (QLAudioPlayPlaying == playState);
    }
    bool isPaused(){
        return (QLAudioPlayPause == playState);
    }
protected:
    const char * filePath;
    QLAudioPlayState playState;
    QLAudioFileInfo  audioFileInfo;
private:
    void readFile();
    void createAudioQueue();
    AudioQueueParameterValue _volume;
};

#endif /* QLPlayer_hpp */
