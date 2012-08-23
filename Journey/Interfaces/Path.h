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

typedef void (^PathSuccess)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^PathFailure)(AFHTTPRequestOperation *operation, NSError *error);

extern NSString * const kPathBaseURLString;

@interface Path : AFHTTPClient

@property (nonatomic, retain) NSURL *baseUrl;

-(id) initWithUsername: (NSString *)username
           andPassword: (NSString *)password;

-(void) getUserSettingsWithSuccess: (PathSuccess)success
                           failure: (PathFailure)failure;

-(void) getMomentFeedHomeNewerThan: (double)date
                           success: (PathSuccess)success
                           failure: (PathFailure)failure;

-(void) getMomentFeedHomeOlderThan: (double)date
                           success: (PathSuccess)success
                           failure: (PathFailure)failure;

-(void) postMomentSeenitOf: (NSArray *)mids
                   success: (PathSuccess)success
                   failure: (PathFailure)failure;

-(void) getMomentCommentsOf: (NSArray *)mids
                    success: (PathSuccess)success
                    failure: (PathFailure)failure;

-(void) postComment: (NSString *)comment
           toMoment: (NSString *)momentID
                 at: (CLLocation *)location
            success: (PathSuccess)success
            failure: (PathFailure)failure;

@end