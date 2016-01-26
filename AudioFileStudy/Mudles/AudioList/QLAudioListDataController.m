//
//  QLAudioListDataController.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/25.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "QLAudioListDataController.h"
#import "CommFunctions.h"
#import "QLAudioFile.h"
#import "QLAudioListModel.h"

@implementation QLAudioListDataController

- (void)test
{
    NSString *mp3Path1 = [[NSBundle mainBundle]pathForResource:@"zhengjiu" ofType:@"mp3"];
    NSString *mp3Path2 = [[NSBundle mainBundle]pathForResource:@"xiangmengyiyangziyou" ofType:@"mp3"];
    NSArray *bundleAudios = @[mp3Path1,mp3Path2];
    for (NSString *path in bundleAudios) {
        
        NSString *toPath = [ApplicationDocumentPath() stringByAppendingPathComponent:[path lastPathComponent]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:toPath]) {
            [[NSFileManager defaultManager]removeItemAtPath:toPath error:nil];
        }
        [[NSFileManager defaultManager]moveItemAtPath:path toPath:toPath error:nil];
    }
}

- (NSArray *)loadAllAudio
{
    [self test];
    NSURL *searchPath = [NSURL fileURLWithPath:ApplicationDocumentPath()];
    NSArray *resourceKeys = @[NSURLIsDirectoryKey,NSURLNameKey];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:searchPath includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
    NSMutableArray *audioFiles = [[NSMutableArray alloc]init];
    
    NSArray *audioExtensions = [QLAudioFile audioFileExtensions];
    
    for (NSURL *fileURL in fileEnumerator) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        
        if ([resourceValues[NSURLIsDirectoryKey]boolValue]) {
            continue;
        }
        
        NSString *fileName = [resourceValues[NSURLNameKey]pathExtension];
        if ([audioExtensions containsObject:fileName]) {
            [audioFiles addObject:fileURL];
        }
    }
    
    NSMutableArray *models = [[NSMutableArray alloc]init];
    
    for (NSURL *url in audioFiles) {
        QLAudioListModel *model =[QLAudioListModel new];
        model.fileURL = url;
        model.songName = [[[url absoluteString]lastPathComponent]stringByDeletingPathExtension];
//        [QLAudioFile alloc]initWithFilePath:<#(NSString *)#> fileType:<#(AudioFileTypeID)#>
//        model.albumImage =
        [models addObject:model];
    }
    
    return (models.count > 0)? models : nil;
}

@end
