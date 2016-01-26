//
//  QLLoadListDataInterface.h
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/26.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QLLoadListDataInterface <NSObject>

@required;
///return [QLAudioListModel] or nil;
- (NSArray *)loadAllAudio;

@end
