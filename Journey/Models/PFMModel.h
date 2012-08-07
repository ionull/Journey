#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

@interface PFMModel : NSObject {
  NSString *_url;
}

@property (nonatomic, copy) NSString *url;

- (ASIHTTPRequest *)requestWithPath:(NSString *)path;
- (ASIFormDataRequest *)requestDataWithPath:(NSString *)path;

@end
