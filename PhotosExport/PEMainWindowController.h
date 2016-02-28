//
//  PEMainWindowController.h
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PEMainWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    
}
@property (assign, nonatomic) BOOL loadingAlbums;
@property (weak, nonatomic) IBOutlet NSOutlineView* outlineView;
@property (weak, nonatomic) IBOutlet NSWindow* exportProgressWindow;
@property (weak, nonatomic) IBOutlet NSTableView* exportProgressTable;

@property (copy, nonatomic) NSString* exportProgressSizeDesc;
@property (assign, nonatomic) NSUInteger exportProgressBytesDone;
@property (assign, nonatomic) NSUInteger exportProgressTotalBytes;
@property (strong, nonatomic) NSMutableArray* exportMessageList;
@property (assign, nonatomic) BOOL exportProgressAbortHidden;
@property (assign, nonatomic) BOOL exportProgressCloseHidden;

- (IBAction)export:(id)sender;
- (IBAction)cancelExport:(id)sender;
- (IBAction)closeExport:(id)sender;
@end
