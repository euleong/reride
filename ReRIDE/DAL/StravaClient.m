//
//  StravaClient.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/4/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "StravaClient.h"

NSString *accessToken;
@implementation StravaClient

- (id)init {
    
    
    // read in api key from plist
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"StravaClient.plist"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"StravaClient" ofType:@"plist"];
    }
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *plistDictionary = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    
    
    accessToken = [plistDictionary objectForKey:@"access_token"];
    NSString *clientSecret = [plistDictionary objectForKey:@"client_secret"];
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