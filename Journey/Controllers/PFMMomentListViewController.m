#import "PFMMomentListViewController.h"
#import "Application.h"
#import "SBJson.h"
#import "DDURLParser.h"
#import "PFMMoment.h"
#import "PFMUser.h"
#import "PFMPhoto.h"
#import "PathAppDelegate.h"

@implementation PFMMomentListViewController

@synthesize
  webView=_webView
;

- (id)init {
  self = [super initWithNibName:@"MomentListView" bundle:nil];
  return self;
}

- (void)loadView {
  [super loadView];

  NSString *webViewPath = [[$ resourcePath] $append:@"/WebView/"];
  NSString *html = [NSString stringWithContentsOfFile:[webViewPath $append:@"index.html"] encoding:NSUTF8StringEncoding error:NULL];
  [[self.webView mainFrame] loadHTMLString:html baseURL:[NSURL fileURLWithPath:webViewPath]];

  PFMUser *user = [NSApp sharedUser];
  user.momentsDelegate = self;

  [[NSApp sharedUser] fetchMomentsNewerThan:0.0];
}

- (void)refreshFeed {
  PFMUser *user = [NSApp sharedUser];
  PFMMoment *firstMoment = nil;
  NSArray *fetchedMoments = user.allMoments;
  if(fetchedMoments && [fetchedMoments count] > 0) {
    firstMoment = [fetchedMoments objectAtIndex:0];
  }
  [user fetchMomentsNewerThan:firstMoment.createdAt];
}

- (void)loadOldMoments {
  PFMUser *user = [NSApp sharedUser];
  PFMMoment *lastMoment = nil;
  NSArray *fetchedMoments = user.allMoments;
  if(fetchedMoments && [fetchedMoments count] > 0) {
    lastMoment = [fetchedMoments $at:([fetchedMoments count] - 1)];
  }

  [user fetchMomentsOlderThan:lastMoment.createdAt];
}

- (NSString *)makeTemplateJSON:(NSArray *)moments {
  PFMUser *user = [NSApp sharedUser];
  NSDictionary *dict = $dict([moments $map:^id (id moment) {
    return [(PFMMoment *)moment toHash];
  }], @"moments",
                             [user.coverPhoto iOSHighResURL], @"coverPhoto",
                             [user.profilePhoto iOSHighResURL], @"profilePhoto");
  return [dict JSONRepresentation];
}

#pragma mark - PFMUserMomentsDelegate

- (void)didFetchMoments:(NSArray *)moments atTop:(BOOL)atTop {
  NSString *javascriptToExecute = nil;
  NSString *json = [self makeTemplateJSON:moments];
  //  NSLog(@">> %@", json);
  if([moments count] > 0) {
    if (atTop) {
      javascriptToExecute = $str(@"Path.renderTemplate('feed', %@, true)", json);
      NSInteger scrollTop = [self webViewScrollTop];
      if(scrollTop > 0 || ![self.view.window isKeyWindow]) {
        [(PathAppDelegate *)[NSApp delegate] highlightStatusItem:YES];
      }
    } else {
      javascriptToExecute = $str(@"Path.renderTemplate('feed', %@, false)", json);
    }
  } else {
    javascriptToExecute = @"Path.didCompleteRefresh()";
  }

  [self.webView stringByEvaluatingJavaScriptFromString:javascriptToExecute];
}

- (void)didFailToFetchMoments {
  [self.webView stringByEvaluatingJavaScriptFromString:@"Path.didCompleteRefresh()"];
}

- (void)postCommentCreate:(NSString*)mid : (NSString*)comment {
    PFMUser *user = [NSApp sharedUser];
    [user postCommentCreate:mid :comment];
}

- (NSInteger)webViewScrollTop {
  return [[self.webView stringByEvaluatingJavaScriptFromString:@"$(document).scrollTop()"] integerValue];
}

#pragma mark - WebUIDelegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
  return nil;
}

#pragma mark - WebFrameLoadDelegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
  if([actionInformation objectForKey:WebActionNavigationTypeKey]) {
    NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
      if(url) {
      NSString *urlString = [url absoluteString];
      if([urlString hasSuffix:@"#refresh_feed"]) {
        [self refreshFeed];
        return;
      } else if([urlString hasSuffix:@"#load_old_moments"]) {
        [self loadOldMoments];
        return;
      } else if([urlString hasSuffix:@"#clear_status_item_highlight"]) {
        [(PathAppDelegate *)[NSApp delegate] highlightStatusItem:NO];
        [self.webView stringByEvaluatingJavaScriptFromString:@"Path.removeHashFragment()"];
        return;
      } else {
          NSString * const fragCreateComment = @"#create_comment";
          BOOL isCreateComment = [urlString rangeOfString:fragCreateComment].location != NSNotFound;
          if(isCreateComment) {
              NSLog(@"urlString: %@", urlString);
              //NSString *javascriptToExecute = nil;
              //javascriptToExecute = $str(@"Path.log('%@')", urlString);
              //[self.webView stringByEvaluatingJavaScriptFromString:javascriptToExecute];
              DDURLParser *parser = [[[DDURLParser alloc] initWithURLString:$str(@"http://localhost/%@", [url fragment])] autorelease];
              NSString *mid = [parser valueForVariable:@"mid"];
              NSString *comment = [parser valueForVariable:@"comment"];
              [self postCommentCreate:mid :comment];
              return;
          }
          //return;
      }
    }
  }
  [listener use];
}

@end
