//
//  ViewController.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/22.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "ViewController.h"
#import "QLAudioFile.h"
#import <AVFoundation/AVFoundation.h>
#import "QLPlayer/QLPrivateAudioPlayer.hpp"
#import "NSTimer+Util.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *albumImage;

@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;

@property (weak, nonatomic) IBOutlet UISlider *durationSlider;

@property (weak, nonatomic) IBOutlet UIStepper *volumeSteper;


@property (strong, nonatomic) QLAudioFile *audioFile;

@end

@implementation ViewController
{
    QLPrivateAudioPlayer *player;
    NSThread *playerThread;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *availableCates = [[AVAudioSession sharedInstance]availableCategories];
    
    NSError *error;
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!error) {
        [[AVAudioSession sharedInstance]setActive:YES error:&error];
    }
    if (error) {
        NSAssert(NO,@"Audio Session set active failed!");
    }else{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:[AVAudioSession sharedInstance]];
    }
    
    NSString *mp3Path = [[NSBundle mainBundle]pathForResource:@"xiangmengyiyangziyou" ofType:@"mp3"];
    QLAudioFile *audioFile = [[QLAudioFile alloc]initWithFilePath:mp3Path fileType:kAudioFileMP3Type];
    NSLog(@"---%@",audioFile);
    self.albumImage.image = [UIImage imageWithData:[audioFile readAlbumImageData]];
    self.audioFile = audioFile;
    
    playerThread = [[NSThread alloc]initWithTarget:self selector:@selector(playThreadMain) object:nil];
    [playerThread start];
    
//    player = new QLPrivateAudioPlayer([mp3Path UTF8String]);
//    player->preparePlay();
//    player->resetVolume(_volumeSteper.value);
    
    __weak __typeof(self)weakSelf = self;
    [NSTimer scheduledWithTimeInterval:0.5 repeats:YES block:^{
        __strong __typeof(weakSelf)self = weakSelf;
        [self updatePlayedTime];
    }];
}

- (void)playThreadMain
{
//    @"xiangmengyiyangziyou" 
    NSString *mp3Path = [[NSBundle mainBundle]pathForResource:@"zhengjiu" ofType:@"mp3"];
    player = new QLPrivateAudioPlayer([mp3Path UTF8String]);
    player->preparePlay();
    player->resetVolume(0.3);
    [[NSRunLoop currentRunLoop]addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop]run];
}

- (void)play
{
    player->play();
}

- (void)pause
{
    player->pause();
}

- (void)resetVolume:(NSNumber *)v
{
    player->resetVolume([v floatValue]);
}

- (void)seek:(NSNumber *)p
{
    player->seekTo([p floatValue]);
}

- (IBAction)changedPlayStateAction:(UIButton *)sender {
    [sender setSelected:!sender.isSelected];
    if (sender.isSelected) {
        [self performSelector:@selector(play) onThread:playerThread withObject:nil waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
    }else{
        [self performSelector:@selector(pause) onThread:playerThread withObject:nil waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
    }
}

- (IBAction)seekAction:(UISlider *)sender {
    [self performSelector:@selector(seek:) onThread:playerThread withObject:@(sender.value) waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
}

- (IBAction)changedVolume:(UIStepper *)sender {
    
   CGFloat v = sender.value / sender.maximumValue;
   [self performSelector:@selector(resetVolume:) onThread:playerThread withObject:@(v) waitUntilDone:YES modes:@[NSRunLoopCommonModes]];
}

- (double)playedProgress
{
   return player->playedProgress();
}

- (void)updatePlayedTime
{
    double p = [self playedProgress];
    self.durationSlider.value = p;
    
    if (player->isPlaying()) {
        
    }
}

- (void)handleInterruption:(NSNotification *)notifi
{
    
}
@end
