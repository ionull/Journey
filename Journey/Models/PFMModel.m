
#import "Application.h"
#import "PFMModel.h"

@implementation PFMModel

@synthesize
  url=_url
;

- (ASIHTTPRequest *)requestWithPath:(NSString *)path {
  NSURL *url = [NSURL URLWithString:$str(@"%@%@", kPathAPIHost, path)];
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  return request;
}

- (ASIFormDataRequest *)requestDataWithPath:(NSString *)path {
    NSURL *url = [NSURL URLWithString:$str(@"%@%@", kPathAPIHost, path)];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    return request;
}

@end
