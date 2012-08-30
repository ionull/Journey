//
//  PathAddThoughtWindowController.m
//  Journey
//
//  Created by tsung on 12-8-29.
//  Copyright (c) 2012年 DecisiveBits. All rights reserved.
//

#import "PathAddThoughtWindowController.h"
#import "Application.h"
#import "PFMUser.h"

@implementation PathAddThoughtWindowController
- (id)init {
    self = [[super initWithWindowNibName:@"PathAddThoughtWindow"]autorelease];
    return self;
}

- (IBAction)actionCancel:(id)sender {
    [self close];
    [self release];
}

- (IBAction)actionSend:(id)sender {
    //start request to send thought
    NSString* thought = [textview_thought string];
    NSMutableArray* sharing = [NSMutableArray array];
    if([checkbox_twitter state] == NSOnState) {
        [sharing addObject:@"twitter"];
    }
    
    [[NSApp sharedUser] postMomentThought:thought sharing:sharing];
    [self actionCancel:nil];
}

@end
