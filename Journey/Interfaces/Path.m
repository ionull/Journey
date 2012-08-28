//
//  Path.m
//  Journey
//
//  Created by tsung on 12-8-20.
//  Copyright (c) 2012年 DecisiveBits. All rights reserved.
//

#import "Path.h"
#import "ConciseKit.h"
#import "SBJson.h"

NSString * const kPathBaseURLString = @"https://api.path.com";

// user
NSString * const kPathUserSettings = @"/3/user/settings";

// moment
NSString * const kPathMomentFeedHome = @"/3/moment/feed/home";
NSString * const kPathMomentSeenit = @"/3/moment/seenit";
NSString * const kPathMomentAdd = @"/3/moment/add";

// comment
NSString * const kPathCommentsAdd = @"/3/moment/comments/add";
NSString * const kPathComments = @"/3/moment/comments";

@interface Path()
@property (readwrite, nonatomic, copy) NSString *username;
@property (readwrite, nonatomic, copy) NSString *password;

@end

@implementation Path

#pragma mark - init

-(id) initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if(!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    return self;
}

+(Path *) getPathInstance {
    return [[Path alloc]autorelease];
}

+(Path *) pathWithUsername:(NSString *)username password:(NSString *)password {
    Path *path = [Path getPathInstance];
    //TODO initWithBaseURL fail, return with nil.
    [path initWithBaseURL:[NSURL URLWithString:kPathBaseURLString]];
    path.username = username;
    path.password = password;
    [path setAuthorizationHeaderWithUsername:path.username password:path.password];
    return path;
}

#pragma mark - helper

-(void) enqueuePathRequestOperationWithMethod: (NSString *)method
                                          path: (NSString *)path
                                    parameters: (NSDictionary *)post
                                       success: (PathSuccess)success
                                       failure: (PathFailure)failure {
    NSDictionary *parameters = nil;
    if(post) {
        parameters = [NSDictionary dictionaryWithObject:[post JSONRepresentation] forKey:@"post"];
    }
    NSURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
    success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if(success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(failure) {
            failure(operation, error);
        }
    }];
    
    [self enqueueHTTPRequestOperation:operation];
}

-(void) enqueuePathRequestOperationGetPath: (NSString *)path
                               success:(PathSuccess)success
                               failure: (PathFailure)failure {
    [self enqueuePathRequestOperationWithMethod: @"GET" path: path parameters: nil success:success failure:failure];
}

-(void) enqueuePathRequestOperationPostPath: (NSString *)path
                                   parameters: (NSDictionary *)parameters
                                      success: (PathSuccess)success
                                    failure: (PathFailure)failure {
    [self enqueuePathRequestOperationWithMethod:@"POST" path:path parameters:parameters success:success failure:failure];
}

-(void) enqueuePathRequestOperationPutPath: (NSString *)path
                                 parameters: (NSDictionary *)parameters
                                    success: (PathSuccess)success
                                    failure: (PathFailure)failure {
    [self enqueuePathRequestOperationWithMethod:@"PUT" path:path parameters:parameters success:success failure:failure];
}

-(void) enqueuePathRequestOperationDeletePath: (NSString *)path
                                    success: (PathSuccess)success
                                    failure: (PathFailure)failure {
    [self enqueuePathRequestOperationWithMethod:@"DELETE" path:path parameters:nil success:success failure:failure];
}

#pragma mark - user

-(void) getUserSettingsWithSuccess:(PathSuccess)success failure:(PathFailure)failure {
    [self enqueuePathRequestOperationGetPath:kPathUserSettings success:success failure:failure];
}

#pragma mark - moment

-(void) getMomentFeedHomeWithPath: (NSString *)path success:(PathSuccess)success failure:(PathFailure)failure {
    [self enqueuePathRequestOperationGetPath:path success:success failure:failure];
}

-(void) getMomentFeedHomeNewerThan:(double)date success:(PathSuccess)success failure:(PathFailure)failure {
    NSString * path = nil;
    
    if (date != 0.0) {
        path = $str(@"%@?newer_than=%f", kPathMomentFeedHome, date);
    } else {
        path = kPathMomentFeedHome;
    }

    [self getMomentFeedHomeWithPath:path success:success failure:failure];
}

-(void) getMomentFeedHomeOlderThan:(double)date success:(PathSuccess)success failure:(PathFailure)failure {
    NSString * path = nil;
    
    if (date != 0.0) {
        path = $str(@"%@?older_than=%f", kPathMomentFeedHome, date);
    } else {
        path = kPathMomentFeedHome;
    }

    [self getMomentFeedHomeWithPath:path success:success failure:failure];
}

-(void) postMomentSeenitOf:(NSArray *)mids success:(PathSuccess)success failure:(PathFailure)failure {
    NSDictionary *post = [NSDictionary dictionaryWithObjectsAndKeys:mids, @"moment_ids", nil];
    [self enqueuePathRequestOperationPostPath:kPathMomentSeenit parameters:post success:success failure:failure];
}

-(void) postMomentAddThought:(NSString *)thought at:(CLLocation *)place sharing:(NSArray *)sharing success:(PathSuccess)success failure:(PathFailure)failure {
    NSDictionary* thoughtDict = [NSDictionary dictionaryWithObject:thought forKey:@"body"];
    NSDictionary* post;
    if(place) {
        NSDictionary* location = [NSDictionary dictionaryWithObjectsAndKeys:$str(@"%+.6f", place.coordinate.latitude), @"lat", $str(@"%+.6f", place.coordinate.longitude), @"lng", nil];
        post = [NSDictionary dictionaryWithObjectsAndKeys:@"thought", @"type", thoughtDict, @"thought", location, @"location", nil];
    } else {
        post = [NSDictionary dictionaryWithObjectsAndKeys:@"thought", @"type", thoughtDict, @"thought", nil];
    }
    
    [self enqueuePathRequestOperationPostPath:kPathMomentAdd parameters:post success:success failure:failure];
}

#pragma mark - comment

-(void) getMomentCommentsOf:(NSArray *)mids success:(PathSuccess)success failure:(PathFailure)failure {
    NSString *query = [mids componentsJoinedByString: @","];
    [self enqueuePathRequestOperationGetPath:$str(@"%@?moment_ids=%@", kPathComments, query) success:success failure:failure];
}

-(void) postComment:(NSString *)comment toMoment:(NSString *)momentID at:(CLLocation *)place success:(PathSuccess)success failure:(PathFailure)failure {
    NSDictionary* post;
    if(place) {
        NSDictionary* location = [NSDictionary dictionaryWithObjectsAndKeys:$str(@"%+.6f", place.coordinate.latitude), @"lat", $str(@"%+.6f", place.coordinate.longitude), @"lng", nil];
        post = [NSDictionary dictionaryWithObjectsAndKeys:momentID, @"moment_id", comment, @"body", location, @"location", nil];
    } else {
        post = [NSDictionary dictionaryWithObjectsAndKeys:momentID, @"moment_id", comment, @"body", nil];
    }

    [self enqueuePathRequestOperationPostPath:kPathCommentsAdd parameters:post success:success failure:failure];
}

@end
