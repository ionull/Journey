//
//  Path.h
//  Journey
//
//  Created by tsung on 12-8-20.
//  Copyright (c) 2012年 DecisiveBits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

extern NSString * const kPathBaseURLString;

@interface Path : AFHTTPClient

@property (nonatomic, retain) NSURL *baseUrl;

-(id) initWithUsername: (NSString *)username
             andPassword: (NSString *)password;

-(void) getUserSettingsWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void) getMomentFeedHomeNewerThan: (double)date
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void) getMomentFeedHomeOlderThan: (double)date
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void) postMomentSeenitOf: (NSArray *)mids
                 success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void) getMomentCommentsOf: (NSArray *)mids
                  success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                  failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

-(void) postComment: (NSString *)comment
           toMoment:  (NSString *)momentID
                 at: (CLLocation *)location
            success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end