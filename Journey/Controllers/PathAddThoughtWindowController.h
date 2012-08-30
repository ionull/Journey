//
//  PathAddThoughtWindowController.h
//  Journey
//
//  Created by tsung on 12-8-29.
//  Copyright (c) 2012年 DecisiveBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PathAddThoughtWindowController : NSWindowController {
    IBOutlet NSButton* button_cancel;
    IBOutlet NSBundle* button_send;
    IBOutlet NSButtonCell* checkbox_twitter;
    IBOutlet NSTextView* textview_thought;
}

- (IBAction)actionCancel:(id)sender;

- (IBAction)actionSend:(id)sender;

@end
