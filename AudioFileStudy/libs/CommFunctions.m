//
//  CommFunctions.m
//  Secret
//
//  Created by xuqianlong on 15/11/7.
//  Copyright (c) 2015年 Debugly. All rights reserved.
//

#import "CommFunctions.h"

@implementation CommFunctions

@end


UIColor* ColorFromHexString(NSString *hex)
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([cString hasPrefix:@"0X"]){
        cString = [cString substringFromIndex:2];
    }else if ([cString hasPrefix:@"#"]){
        cString = [cString substringFromIndex:1];
    }
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1];
}

CGFloat screenWidth()
{
    static CGFloat width = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        width = [UIScreen mainScreen].bounds.size.width;
    });
    return width;
}

NSString *safeString(NSString *str)
{
    if (str) {
        return [[NSString alloc]initWithString:[str description]];
    }
    return @"";
}

//    /var/mobile/Containers/Data/Application/A143A6B5-B941-4217-B881-9A6B51530CE1/Library/avatorImages/currentImage.jpg
//    /var/mobile/Containers/Data/Application/F70A24F8-FD94-40AC-9C2B-937724772239/Library/avatorImages/currentImage.jpg

NSString *ApplicationDocumentPath()
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}
