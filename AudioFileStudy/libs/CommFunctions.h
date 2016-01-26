//
//  CommFunctions.h
//  Secret
//
//  Created by xuqianlong on 15/11/7.
//  Copyright (c) 2015年 Debugly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CommFunctions : NSObject

@end


//c functions

UIColor* ColorFromHexString(NSString *hex);

CGFloat screenWidth();

NSString *safeString(NSString *str);

//ios8 每次都不一样；需要每次都调用，不能记录 Document的路径；
NSString *ApplicationDocumentPath();