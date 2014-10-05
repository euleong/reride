//
//  StravaClient.h
//  ReRIDE
//
//  Created by Eugenia Leong on 10/4/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "BDBOAuth1RequestOperationManager.h"

@interface StravaClient:BDBOAuth1RequestOperationManager

- (id)init;

- (AFHTTPRequestOperation *)getAllActivitiesByType:(NSString *)type success:(void (^)(AFHTTPRequestOperation *operation, id response))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (AFHTTPRequestOperation *)getStreamDataById:(NSString *)activityId type:(NSString *)type success:(void (^)(AFHTTPRequestOperation *operation, id response))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end