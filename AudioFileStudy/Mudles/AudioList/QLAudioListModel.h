//
//  QLAudioListModel.h
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/25.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QLAudioListModel : NSObject

@property (nonatomic, strong)NSURL *fileURL;
@property (nonatomic, copy) NSString *songName;
@property (nonatomic, copy) NSString *albumName;
@property (nonatomic, strong)UIImage *albumImage;
@property (nonatomic, assign)CGFloat  duration;

@end
