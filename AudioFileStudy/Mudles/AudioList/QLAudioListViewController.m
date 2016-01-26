//
//  QLAudioListViewController.m
//  AudioFileStudy
//
//  Created by xuqianlong on 16/1/25.
//  Copyright © 2016年 Debugly. All rights reserved.
//

#import "QLAudioListViewController.h"
#import "QLAudioListDataController.h"
#import "QLAudioListCell.h"

static NSString *const QLAudioListCellIndentifier = @"QLAudioListCellIndentifier";

@interface QLAudioListViewController ()

@property (nonatomic, strong) QLAudioListDataController *dataCtrl;
@property (nonatomic, strong) NSArray *audioModels;

@end

@implementation QLAudioListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[QLAudioListCell class] forCellReuseIdentifier:QLAudioListCellIndentifier];
    [self loadDatas];
}

- (void)loadDatas
{
    self.audioModels = [self.dataCtrl loadAllAudio];
}
#pragma mark - tb datasource and delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.audioModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    QLAudioListCell *cell = [tableView dequeueReusableCellWithIdentifier:QLAudioListCellIndentifier forIndexPath:indexPath];
    cell.model = self.audioModels[indexPath.row];
    return cell;
}

#pragma mark - getter

- (QLAudioListDataController *)dataCtrl
{
    if (!_dataCtrl) {
        _dataCtrl = [[QLAudioListDataController alloc]init];
    }
    return _dataCtrl;
}

@end
