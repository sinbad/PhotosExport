//
//  PEMainWindowController.h
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PEMainWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate> {
    
}
@property (assign, nonatomic) BOOL loadingAlbums;
@property (weak, nonatomic) IBOutlet NSOutlineView* outlineView;
@property (weak, nonatomic) IBOutlet NSWindow* exportProgressWindow;
@property (copy, nonatomic) NSString* exportProgressItem;
@property (copy, nonatomic) NSString* exportProgressSizeDesc;
@property (assign, nonatomic) NSUInteger exportProgressBytesDone;
@property (assign, nonatomic) NSUInteger exportProgressTotalBytes;

- (IBAction)export:(id)sender;
- (IBAction)cancelExport:(id)sender;
@end
