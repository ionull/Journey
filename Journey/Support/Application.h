#import "ConciseKit.h"
#import "NSApplication+SharedObjects.h"
#import "NSDictionary+PFMAdditions.h"
#import "NSMutableDictionary+PFMAdditions.h"
#import "NSDate+SCAdditions.h"
#import "NSWindow+PFMAdditions.h"

#define kPathAPIHost                  @"https://api.path.com"
#define kPathDefaultsEmailKey         @"user_email"
#define kPathKeychainServiceName      @"Journey"
#define kMomentsAPIPath               @"/3/moment/feed/home"

#define kPathAPIHostWeb               @"https://path.com"
#define kCommentsAddAPIPath           @"/3/moment/comments/add"
#define kCommentsAPIPath              @"/3/moment/comments"
#define kSeenMomentsAPIPath           @"/3/moment/seenit"