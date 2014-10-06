//
//  StravaActivity.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/5/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "StravaActivity.h"

@implementation StravaActivity

// convert m/s to mi/h string
+ (NSString *)msToMphStr:(float)number {
    return [NSString stringWithFormat:@"%.02f", number*2.23694];;
}

@end
