#import "NSApplication+SharedObjects.h"
#import "PFMUser.h"
#import "Application.h"

static PFMUser *_sharedUser = nil;
static NSMutableDictionary *_sharedLocations = nil;
static NSMutableDictionary *_sharedPlaces = nil;
static NSMutableDictionary *_sharedUsers = nil;
static CLLocationManager *_sharedLocationManager = nil;
static CLLocation *_sharedLocation = nil;
static NSError *_sharedLocationNotAllow = nil;
@implementation NSApplication (SharedObjects)

- (PFMUser *)sharedUser {
  @synchronized(self) {
    if(!_sharedUser) {
      _sharedUser = [PFMUser new];
    }
  }
  return _sharedUser;
}

- (NSMutableDictionary *)sharedLocations {
  @synchronized(self) {
    if(!_sharedLocations) {
      _sharedLocations = $mdict(nil);
    }
  }
  return _sharedLocations;
}

- (NSMutableDictionary *)sharedUsers {
  @synchronized(self) {
    if(!_sharedUsers) {
      _sharedUsers = $mdict(nil);
    }

    return _sharedUsers;
  }
}

- (CLLocationManager *)sharedLocationManager {
    @synchronized(self) {
        if(!_sharedLocationManager) {
            _sharedLocationManager = [[CLLocationManager alloc] init];
            _sharedLocationManager.delegate = self;
            _sharedLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
            
            // Set a movement threshold for new events.
            _sharedLocationManager.distanceFilter = 500;
            
            [_sharedLocationManager startUpdatingLocation];
        }
        return _sharedLocationManager;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locaion fail!%@", error);
    
    //user not allow..
    _sharedLocationNotAllow = error;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0)
    {
    }
    NSLog(@"latitude %+.6f, longitude %+.6f\n",
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude);
    _sharedLocation = newLocation;
    
    //now user allow location request again.. reset error
    _sharedLocationNotAllow = nil;
}

- (CLLocation *)sharedLocation {
    return _sharedLocation;
}

- (NSError *)sharedLocationNotAllow {
    return _sharedLocationNotAllow;
}

- (NSMutableDictionary *)sharedPlaces {
  @synchronized(self) {
    if(!_sharedPlaces) {
      _sharedPlaces = $mdict(nil);
    }
  }
  return _sharedPlaces;
}

- (PFMUser *)resetSharedUser {
  _sharedUser = nil;
  return [self sharedUser];
}

- (NSMutableDictionary *)resetSharedLocations {
  _sharedLocations = nil;
  return [self sharedLocations];
}

- (NSMutableDictionary *)resetSharedPlaces {
  _sharedPlaces = nil;
  return [self sharedPlaces];
}

- (NSMutableDictionary *)resetSharedUsers {
  _sharedUsers = nil;
  return [self sharedUsers];
}


@end
