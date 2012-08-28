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
    
    //request location access
    //TODO update location
  [NSApp sharedLocationManager];
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
    [user postCommentCreate:mid :[comment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)didFetchComments:(NSString *)comments {
    NSString *javascriptToExecute = nil;
    // replace ' with \' to avoid failure
    javascriptToExecute = $str(@"Path.didFetchedComments('%@')", [comments stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]);
    
    [self.webView stringByEvaluatingJavaScriptFromString:javascriptToExecute];
}

- (NSInteger)webViewScrollTop {
  return [[self.webView stringByEvaluatingJavaScriptFromString:@"$(document).scrollTop()"] integerValue];
}

#pragma mark - WebUIDelegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
  return nil;
}

#pragma mark - WebFrameLoadDelegate

- (DDURLParser *)getParser: (NSString *)fragment {
    return [[[DDURLParser alloc] initWithURLString:$str(@"http://localhost/%@", fragment)] autorelease];
}

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
          NSString * const fragNone = @"_";
          if ([[url fragment] isEqualToString:fragNone]) {
              //do nothing
              return;
          }
          
          NSString * const fragCreateComment = @"#create_comment";
          BOOL isCreateComment = [urlString rangeOfString:fragCreateComment].location != NSNotFound;
          if(isCreateComment) {
              DDURLParser *parser = [self getParser:[url fragment]];
              NSString *mid = [parser valueForVariable:@"mid"];
              NSString *comment = [parser valueForVariable:@"comment"];
              [self postCommentCreate:mid :comment];
              return;
          }
          
          NSString * const fragGetComments = @"#get_comments";
          BOOL isGetComments = [urlString rangeOfString:fragGetComments].location != NSNotFound;
          if(isGetComments) {
              DDURLParser *parser = [self getParser:[url fragment]];
              NSString *mids = [parser valueForVariable:@"mids"];
              PFMUser *user = [NSApp sharedUser];
              [user getComments: mids];
              return;
          }
          
          NSLog(@"urlString: %@", urlString);
          NSString * const fragSeenMoments = @"#seen_it";
          BOOL isSeenMoments = [urlString rangeOfString:fragSeenMoments].location != NSNotFound;
          if(isSeenMoments) {
              DDURLParser *parser = [self getParser:[url fragment]];
              NSString *mids = [parser valueForVariable:@"mids"];
              PFMUser *user = [NSApp sharedUser];
              [user postMomentSeenit: [mids componentsSeparatedByString:@","]];
              return;
          }
          
          NSString * const fragMomentsAddThought = @"#add_thought";
          BOOL isAddThought = [urlString rangeOfString:fragMomentsAddThought].location != NSNotFound;
          if(isAddThought) {
              DDURLParser *parser = [self getParser:[url fragment]];
              NSString *thought = [parser valueForVariable:@"thought"];
              PFMUser *user = [NSApp sharedUser];
              NSMutableArray *sharing = [NSMutableArray array];
              [sharing addObject:@"twitter"];//TODO select sharing
              [user postMomentThought:[thought stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] sharing:sharing];
              return;
          }
      }
    }
  }
  [listener use];
}

@end
