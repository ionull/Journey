#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PFMUser.h"

@interface PFMMomentListViewController : NSViewController <
  PFMUserMomentsDelegate
> {
  WebView *_webView;
}

@property (nonatomic, retain) IBOutlet WebView *webView;

- (void)refreshFeed;
- (void)loadOldMoments;
- (void)postCommentCreate:(NSString*)mid : (NSString*)comment;
- (NSInteger)webViewScrollTop;
- (NSString *)makeTemplateJSON:(NSArray *)moments;

@end
