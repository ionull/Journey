#import "PFMUser.h"
#import "PFMMoment.h"
#import "PFMComment.h"
#import "Application.h"
#import "SBJson.h"
#import "SSKeychain.h"
#import "PFMPhoto.h"
#import "PFMLocation.h"
#import "PFMPlace.h"
#import "Path.h"

@interface PFMUser ()

- (void)reset;
@end

@implementation PFMUser

@synthesize
  oid=_oid
, email=_email
, password=_password
, signingIn=_signingIn
, signedIn=_signedIn
, fetchingMoments=_fetchingMoments
, firstName=_firstName
, lastName=_lastName
, signInDelegate=_signInDelegate
, momentsDelegate=_momentsDelegate
, fetchedMoments=_fetchedMoments
, coverPhoto=_coverPhoto
, profilePhoto=_profilePhoto
, allMomentIds=_allMomentIds
, allMoments=_allMoments
;

- (id) init {
  if (self = [super init]) {
    [self reset];
  }
  return self;
}

- (void)reset {
  self.oid = nil;
  self.email = nil;
  self.password = nil;
  self.signingIn = NO;
  self.signedIn = NO;
  self.fetchingMoments = NO;
  self.firstName = nil;
  self.lastName = nil;
  self.fetchedMoments = nil;
  self.coverPhoto = nil;
  self.profilePhoto = nil;
  self.allMomentIds = $mdict(nil);
  self.allMoments = $marr(nil);
}

- (void)signIn {
    self.signingIn = YES;
    
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client getUserSettingsWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([[operation response] statusCode] == 200) {
            NSDictionary *dict = responseObject;
            self.firstName = [[dict objectOrNilForKey:@"settings"] objectOrNilForKey:@"user_first_name"];
            self.lastName  = [[dict objectOrNilForKey:@"settings"] objectOrNilForKey:@"user_last_name"];
            [self saveCredentials];
            self.signedIn = YES;
            [self.signInDelegate didSignIn];
        } else if([[operation response] statusCode] == 500) {
            [self.signInDelegate didFailSignInDueToPathError];
        } else {
            [self.signInDelegate didFailSignInDueToInvalidCredentials];
        }
        self.signingIn = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.signInDelegate didFailSignInDueToRequestError];
        self.signingIn = NO;
    }];
}

- (void) didFetchMomentsSuccessWithOperation: (AFHTTPRequestOperation *) operation resonse:(id) responseObject atTop:(BOOL) atTop {
    if([[operation response] statusCode] == 200) {
        [self parseMomentsJSON:[operation responseString] insertAtTop:atTop];
        [self.momentsDelegate didFetchMoments:[self fetchedMoments] atTop:atTop];
    } else {
        [self.momentsDelegate didFailToFetchMoments];
    }
    self.fetchingMoments = NO;
}

- (void) didFetchMomentsFailureWithOperation: (AFHTTPRequestOperation *) operation error:(NSError *) error {
    [self.momentsDelegate didFailToFetchMoments];
    self.fetchingMoments = NO;
}

- (void)fetchMomentsNewerThan:(double)date {
    self.fetchingMoments = YES;
    
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client getMomentFeedHomeNewerThan:date success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self didFetchMomentsSuccessWithOperation:operation
                                          resonse:responseObject
                                            atTop:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self didFetchMomentsFailureWithOperation:operation error:error];
    }];
}

- (void)fetchMomentsOlderThan:(double)date {
    self.fetchingMoments = YES;
    
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client getMomentFeedHomeOlderThan:date success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self didFetchMomentsSuccessWithOperation:operation
                                          resonse:responseObject
                                            atTop:NO];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self didFetchMomentsFailureWithOperation:operation error:error];
    }];
}

- (void)postCommentCreate:(NSString*)mid : (NSString*)comment {
    //request location
    [NSApp sharedLocationManager];
    
    //NSDictionary* location = [NSDictionary dictionaryWithObjectsAndKeys:@"26.093885", @"lat", @"119.30904", @"lng", nil];
    //NSDictionary* location = [NSDictionary dictionaryWithObjectsAndKeys:@"37.418648", @"lat", @"-122.03125", @"lng", nil];
    
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client postComment:comment toMoment:mid at:[NSApp sharedLocation] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([[operation response] statusCode] == 200) {
            [self parseCommentsJSON:[operation responseString]];
        } else {
            //
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
    }];
}

- (void)postMomentSeenit:(NSArray*)mids {
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client postMomentSeenitOf:mids success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
    }];
}

- (void)getComments:(NSString*)mids {
    Path *client = [[Path alloc] initWithUsername:self.email andPassword:self.password];
    
    [client getMomentCommentsOf:[mids componentsSeparatedByString:@","] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([[operation response] statusCode] == 200) {
            [self parseCommentsJSON:[operation responseString]];
        } else {
            //
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
    }];
}

- (void)parseMomentsJSON:(NSString *)json
             insertAtTop:(BOOL)atTop {
  self.fetchedMoments = $marr(nil);
  NSDictionary *dict = [json JSONValue];
  for(NSDictionary * rawMoment in [dict objectOrNilForKey:@"moments"]) {
    PFMMoment * moment = [PFMMoment momentFrom:rawMoment];
    if (![self.allMomentIds objectForKey:moment.oid]) {
      [self.fetchedMoments addObject:moment];
      [self.allMomentIds setObject:moment forKey:moment.oid];
    }
  }

  // Don't do anything if the API hasn't returned anything
  if([self.fetchedMoments count] == 0) {
    return;
  } else {
    // Otherwise insert elements either at the top/bottom depending on atTop
    NSUInteger insertAt = 0;
    if (!atTop) { insertAt = [self.allMoments count]; }

    NSRange range = NSMakeRange(insertAt, [self.fetchedMoments count]);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.allMoments insertObjects:self.fetchedMoments atIndexes:indexSet];
  }

  // Set the ID
  self.oid = [(NSDictionary *)[(NSDictionary *)[dict objectOrNilForKey:@"cover"] objectOrNilForKey:@"user"] objectOrNilForKey:@"id"];
  // Get the Cover Photo
  NSDictionary * coverPhotoDictionary = [(NSDictionary *)[dict objectOrNilForKey:@"cover"] objectOrNilForKey:@"photo"];
  self.coverPhoto = [PFMPhoto photoFrom:coverPhotoDictionary];
  // Get the Profile Photo dictionary from the users dictionary and set the profile photo
  NSDictionary * profilePhotoDictionary = [(NSDictionary *)[(NSDictionary *)[dict objectOrNilForKey:@"users"] objectOrNilForKey:self.oid] objectOrNilForKey:@"photo"];
  self.profilePhoto = [PFMPhoto photoFrom:profilePhotoDictionary];
  // Get the locations map
  NSDictionary * locationsDict = (NSDictionary *)[dict objectOrNilForKey:@"locations"];

  [locationsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    PFMLocation * location = [PFMLocation locationFrom:(NSDictionary *)obj];
    [[NSApp sharedLocations] setObject:location forKey:key];
  }];

  // Get the places map
  NSDictionary * placesDict = (NSDictionary *)[dict objectOrNilForKey:@"places"];

  [placesDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    PFMPlace * place = [PFMPlace placeFrom:(NSDictionary *)obj];
    [[NSApp sharedPlaces] setObject:place forKey:key];
  }];

  // Get the global users map
  NSDictionary * usersDict = (NSDictionary *)[dict objectOrNilForKey:@"users"];
  [usersDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    NSDictionary * userDict = (NSDictionary *)obj;
    NSString * userId = (NSString *)key;

    PFMUser * user = [PFMUser new];
    user.oid = userId;
    user.firstName    = [userDict objectOrNilForKey:@"first_name"];
    user.lastName     = [userDict objectOrNilForKey:@"last_name"];
    user.profilePhoto = [PFMPhoto photoFrom:[userDict objectOrNilForKey:@"photo"]];

    [[NSApp sharedUsers] setObject:user forKey:userId];
  }];
}

- (void)parseCommentsJSON:(NSString *)json {
    NSMutableDictionary *dict = [json JSONValue];
    
    // Get the locations map
    NSDictionary * locationsDict = (NSDictionary *)[dict objectOrNilForKey:@"locations"];
    
    [locationsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PFMLocation * location = [PFMLocation locationFrom:(NSDictionary *)obj];
        [[NSApp sharedLocations] setObject:location forKey:key];
    }];
    
    // Get the global users map
    NSDictionary * usersDict = (NSDictionary *)[dict objectOrNilForKey:@"users"];
    [usersDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSDictionary * userDict = (NSDictionary *)obj;
        NSString * userId = (NSString *)key;
        
        PFMUser * user = [PFMUser new];
        user.oid = userId;
        user.firstName    = [userDict objectOrNilForKey:@"first_name"];
        user.lastName     = [userDict objectOrNilForKey:@"last_name"];
        user.profilePhoto = [PFMPhoto photoFrom:[userDict objectOrNilForKey:@"photo"]];
        
        [[NSApp sharedUsers] setObject:user forKey:userId];
    }];
    
    NSMutableDictionary* comments = (NSMutableDictionary *)[dict objectOrNilForKey:@"comments"];
    for(NSString* key in [comments allKeys]) {
        NSMutableArray* commentsDict = (NSMutableArray*)[comments objectForKey:key];
        for (int idx = 0; idx < [commentsDict count]; idx ++) {
            PFMComment * comment = [PFMComment commentFrom:[commentsDict objectAtIndex:idx]];
            //re-organize data
            [commentsDict replaceObjectAtIndex:idx withObject:[[comment JSONRepresentation]JSONValue]];
        }
        [comments setValue:commentsDict forKey:key];
    }
    [dict setValue:comments forKey:@"comments"];
    
    [self.momentsDelegate didFetchComments:[dict JSONRepresentation]];
}

- (void)saveCredentials {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:self.email forKey:kPathDefaultsEmailKey];
  [defaults synchronize];
  [SSKeychain setPassword:self.password forService:kPathKeychainServiceName account:self.email];
}

- (void)loadCredentials {
  self.email = [[NSUserDefaults standardUserDefaults] objectForKey:kPathDefaultsEmailKey];
  self.password = [SSKeychain passwordForService:kPathKeychainServiceName account:self.email];
}

- (void)deleteCredentials {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kPathDefaultsEmailKey];
  [defaults synchronize];
  [SSKeychain deletePasswordForService:kPathKeychainServiceName account:self.email];
  [self reset];
}

- (NSDictionary *) toHash {
  NSMutableDictionary * userDict = $mdict(self.oid, @"id");

  [userDict setObjectOrNil:self.email                 forKey:@"email"];
  [userDict setObjectOrNil:self.firstName             forKey:@"firstName"];
  [userDict setObjectOrNil:self.lastName              forKey:@"lastName"];
  [userDict setObjectOrNil:[self.coverPhoto toHash]   forKey:@"coverPhoto"];
  [userDict setObjectOrNil:[self.profilePhoto toHash] forKey:@"profilePhoto"];

  return userDict;
}

- (NSString *) JSONRepresentation {
  return [[self toHash] JSONRepresentation];
}

@end
