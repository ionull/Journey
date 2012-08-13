#import "PFMUser.h"
#import "PFMMoment.h"
#import "PFMComment.h"
#import "Application.h"
#import "SBJson.h"
#import "SSKeychain.h"
#import "PFMPhoto.h"
#import "PFMLocation.h"
#import "PFMPlace.h"

@interface PFMUser ()

- (void)reset;
- (ASIHTTPRequest *)fetchMomentsWithPath:(NSString *)path
                                   atTop:(BOOL)atTop;

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

- (ASIHTTPRequest *)signIn {
  self.signingIn = YES;
  __block ASIHTTPRequest *request = [self requestWithPath:@"/3/user/settings"];
  [request addBasicAuthenticationHeaderWithUsername:self.email andPassword:self.password];

  [request setCompletionBlock:^{
    if(request.responseStatusCode == 200) {
      NSDictionary *dict = [[request responseString] JSONValue];
      self.firstName = [[dict objectOrNilForKey:@"settings"] objectOrNilForKey:@"user_first_name"];
      self.lastName  = [[dict objectOrNilForKey:@"settings"] objectOrNilForKey:@"user_last_name"];
      [self saveCredentials];
      self.signedIn = YES;
      [self.signInDelegate didSignIn];
    } else if (request.responseStatusCode == 500) {
      [self.signInDelegate didFailSignInDueToPathError];
    } else {
      [self.signInDelegate didFailSignInDueToInvalidCredentials];
    }
    self.signingIn = NO;
  }];

  [request setFailedBlock:^{
    [self.signInDelegate didFailSignInDueToRequestError];
    self.signingIn = NO;
  }];

  [request startAsynchronous];
  return request;
}

- (ASIHTTPRequest *)fetchMomentsNewerThan:(double)date {
  NSString * path = nil;

  if (date != 0.0) {
    path = $str(@"%@?newer_than=%f", kMomentsAPIPath, date);
  } else {
    path = kMomentsAPIPath;
  }

  return [self fetchMomentsWithPath:path atTop:YES];
}

- (ASIHTTPRequest *)fetchMomentsOlderThan:(double)date {
  NSString * path = nil;

  if (date != 0.0) {
    path = $str(@"%@?older_than=%f", kMomentsAPIPath, date);
  } else {
    path = kMomentsAPIPath;
  }

  return [self fetchMomentsWithPath:path atTop:NO];
}


- (ASIHTTPRequest *)fetchMomentsWithPath:(NSString *)path
                                   atTop:(BOOL)atTop {
  self.fetchingMoments = YES;

  __block ASIHTTPRequest * request = [self requestWithPath:path];

  [request addBasicAuthenticationHeaderWithUsername:self.email andPassword:self.password];

  [request setCompletionBlock:^{
    if(request.responseStatusCode == 200) {
      [self parseMomentsJSON:[request responseString] insertAtTop:atTop];

      [self.momentsDelegate didFetchMoments:[self fetchedMoments] atTop:atTop];
    } else {
      [self.momentsDelegate didFailToFetchMoments];
    }
    self.fetchingMoments = NO;
  }];

  [request setFailedBlock:^{
    [self.momentsDelegate didFailToFetchMoments];
  }];

  [request startAsynchronous];
  return request;
}

- (ASIFormDataRequest *)postCommentCreate:(NSString*)mid : (NSString*)comment {
    __block ASIFormDataRequest * request = [self requestDataWithPath:kCommentsAPIPath];
    
    [request addBasicAuthenticationHeaderWithUsername:self.email andPassword:self.password];
    
    //NSDictionary* location = [NSDictionary dictionaryWithObjectsAndKeys:@"37.418648", @"lat", @"-122.03125", @"lng", nil];
    NSDictionary* post = [NSDictionary dictionaryWithObjectsAndKeys:mid, @"moment_id", [comment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"body", nil];//location, @"location", nil];

    
    [request setPostFormat:ASIMultipartFormDataPostFormat];
    [request setPostValue:[post JSONRepresentation] forKey:@"post"];
    // [request setPostValue:@"{lat:26.093885,lng:119.30904" forKey:@"location"];
    
    [request setCompletionBlock:^{
        if(request.responseStatusCode == 200) {
            [self parseCommentsJSON:[request responseString]];
            
            //[self.momentsDelegate didFetchComments:[request responseString]];
        } else {
            //[self.momentsDelegate didFailToFetchMoments];
        }
    }];
    
    [request setFailedBlock:^{
        //[self.momentsDelegate didFailToFetchMoments];
    }];
    
    //[self parseCommentsJSON:@"{\"comments\": {\"502636cf06727b26630224df\": [{\"body\": \"\u96e8\u540e\u5c0f\u6eaa\", \"created\": 1344681588.182, \"id\": \"502636cf06727b26630224e0\", \"location_id\": \"502636d78319cd04941ad611\", \"moment_id\": \"502636cf06727b26630224df\", \"state\": \"live\", \"user_id\": \"501a66e2fa63b3744c000a31\"}, {\"body\": \"\u4f60\u5bb6\u9644\u8fd1\u5417\uff1f\", \"created\": 1344826240.369075, \"id\": \"50286b8021c7ea54f4049311\", \"moment_id\": \"502636cf06727b26630224df\", \"state\": \"live\", \"user_id\": \"4db7b2e46e5e6a75790000db\"}]}, \"emotions\": {}, \"locations\": {\"502636d78319cd04941ad611\": {\"created\": 1344681588.182, \"id\": \"502636d78319cd04941ad611\", \"lat\": 24.94327, \"lng\": 118.31857, \"location\": {\"administrative_area_level_1\": \"Fujian\", \"city\": \"Quanzhou\", \"city_id\": \"4ec319876a9eba1db6000025\", \"country\": \"CN\", \"country_name\": \"China\", \"gc\": \"g\", \"lat\": 24.94327, \"lng\": 118.31857, \"lnglat\": [118.31857, 24.94327], \"province\": \"Fujian\", \"province_name\": \"Fujian\", \"sublocality\": \"Nan'an\"}, \"user_id\": \"501a66e2fa63b3744c000a31\"}}, \"nudges\": {\"502636cf06727b26630224df\": []}, \"seen_it_totals\": {\"502636cf06727b26630224df\": 2}, \"users\": {\"4db7b2e46e5e6a75790000db\": {\"created_at\": \"2011-04-27 06:08:37\", \"first_name\": \"Tsung\", \"gender\": \"male\", \"id\": \"4db7b2e46e5e6a75790000db\", \"last_name\": \"Wu\", \"photo\": {\"ios\": {\"1x\": {\"file\": \"processed_80x80.jpg\", \"height\": 80, \"width\": 80}, \"2x\": {\"file\": \"processed_160x160.jpg\", \"height\": 160, \"width\": 160}}, \"original\": {\"file\": \"original.jpg\", \"height\": 160, \"width\": 160}, \"url\": \"https://s3-us-west-1.amazonaws.com/images.path.com/profile_photos/0570d1783b550ccbaee0739c58cca81e46ab57c6\", \"version\": 3}, \"primary_network\": \"path\", \"state\": \"enabled\", \"username\": \"ioNull\"}, \"501a66e2fa63b3744c000a31\": {\"created_at\": \"2012-08-02 11:39:14\", \"first_name\": \"congwei\", \"gender\": \"male\", \"id\": \"501a66e2fa63b3744c000a31\", \"last_name\": \"hong\", \"primary_network\": \"path\", \"state\": \"enabled\", \"username\": \"congwei-hong\"}}}"];
    [request startAsynchronous];
    return request;
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
    NSMutableDictionary* comments = (NSMutableDictionary *)[dict objectOrNilForKey:@"comments"];
    for(NSString* key in comments) {
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
