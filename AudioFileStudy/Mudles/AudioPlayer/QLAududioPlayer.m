//
//  QLAududioPlayer.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/26.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "QLAududioPlayer.h"
#import "QLPrivateAudioPlayer.hpp"

@interface QLAududioPlayer ()
{
    QLPrivateAudioPlayer *pAudioPlayer;
}

@end

@implementation QLAududioPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (!pAudioPlayer) {
            pAudioPlayer = new QLPrivateAudioPlayer();
        }
    }
    return self;
}

+ (instancetype)sharedAudioPlayer
{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

+ (void)audioPlayerThreadEntryPoint:(id)obj
{
    @autoreleasepool {
        [[NSThread currentThread]setName:@"ql.thread.AudioPlayer"];
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runloop run];
    }
}

+ (NSThread *)audioPlayerThread
{
    static  NSThread *playerThread = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        playerThread = [[NSThread alloc]initWithTarget:self selector:@selector(audioPlayerThreadEntryPoint:) object:nil];
        [playerThread start];
    });
    return playerThread;
}

- (void)playTheURL:(NSURL *)url
{
    //TODO;
}
@end
