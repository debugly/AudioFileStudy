//
//  QLAudioListCell.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/25.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "QLAudioListCell.h"
#import "QLAudioListModel.h"

@interface QLAudioListCell ()

@end

@implementation QLAudioListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)setModel:(QLAudioListModel *)model
{
    if (_model != model) {
        _model = model;
        [self updateSubviews];
    }
}

- (void)updateSubviews
{
    self.imageView.image = self.model.albumImage;
    self.textLabel.text = self.model.songName;
    self.detailTextLabel.text = self.model.albumName;
}

@end
