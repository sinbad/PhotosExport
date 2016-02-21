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

- (IBAction)export:(id)sender;
@end
