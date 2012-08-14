#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>

@class PFMUser;

@interface NSApplication (SharedObjects)

- (PFMUser *)sharedUser;
- (NSMutableDictionary *)sharedLocations;
- (NSMutableDictionary *)sharedPlaces;
- (NSMutableDictionary *)sharedUsers;

- (PFMUser *)resetSharedUser;
- (NSMutableDictionary *)resetSharedLocations;
- (NSMutableDictionary *)resetSharedPlaces;
- (NSMutableDictionary *)resetSharedUsers;

- (CLLocationManager *) sharedLocationManager;
- (CLLocation *) sharedLocation;
- (NSError *) sharedLocationNotAllow;
@end
