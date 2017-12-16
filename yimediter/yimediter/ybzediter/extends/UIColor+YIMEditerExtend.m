//
//  UIColor+YIMEditerExtend.m
//  yimediter
//
//  Created by ybz on 2017/12/3.
//  Copyright © 2017年 ybz. All rights reserved.
//

#import "UIColor+YIMEditerExtend.h"

@implementation UIColor (YIMEditerExtend)

-(NSString*)hexString{
    NSString *colorString = [[CIColor colorWithCGColor:self.CGColor] stringRepresentation];
    NSArray *parts = [colorString componentsSeparatedByString:@" "];
    
    NSMutableString *hexString = [NSMutableString stringWithString:@"#"];
    for (int i = 0; i < 3; i ++) {
        [hexString appendString:[NSString stringWithFormat:@"%02X", (int)([parts[i] floatValue] * 255)]];
    }
    return [hexString copy];
}
+(nonnull UIColor*)colorWithHexString:(NSString*)hexStr{
    CGFloat r, g, b, a;
//    BOOL isSuccess = hexStrToRGBA(hexStr, &r, &g, &b, &a);
//    if(isSuccess){}
//    NSAssert(isSuccess, @"请输入正确的16进制颜色");
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

@end
