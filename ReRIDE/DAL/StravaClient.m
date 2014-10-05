//
//  StravaClient.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/4/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "StravaClient.h"

NSString * const accessToken = @"ac8a2fbc9a3ab1ff40ee00cfc99e2fc0ca20cdc4";
NSString * const clientSecret = @"be35119ec86f4a9e209b4f3b1af2fbcaae3e808e";

@implementation StravaClient

- (id)init {
    NSURL *baseURL = [NSURL URLWithString:@"https://www.strava.com/"];
    self = [super initWithBaseURL:baseURL consumerKey:accessToken consumerSecret:clientSecret];
    if (self) {
        BDBOAuthToken *token = [BDBOAuthToken tokenWithToken:accessToken secret:clientSecret expiration:nil];
        [self.requestSerializer saveAccessToken:token];
    }
    return self;
}

- (AFHTTPRequestOperation *)getAllActivitiesByType:(NSString *)type success:(void (^)(AFHTTPRequestOperation *operation, id response))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    NSDictionary *parameters = @{@"per_page": @"200", @"access_token":accessToken};
    
    return [self GET:@"api/v3/activities" parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)getStreamDataById:(NSString *)activityId type:(NSString *)type success:(void (^)(AFHTTPRequestOperation *operation, id response))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    NSDictionary *parameters = @{@"resolution": @"medium", @"access_token":accessToken};
    
    NSString *url = [NSString stringWithFormat:@"api/v3/activities/%@/streams/%@", activityId, type];
    return [self GET:url parameters:parameters success:success failure:failure];
}

@end