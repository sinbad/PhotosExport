//
//  PEAppDelegate.m
//  PhotosExport
//
//  Created by Steven Streeting on 18/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAppDelegate.h"
#import "PEMainWindowController.h"
#import "PEAlbumTypeImageTransformer.h"

@interface PEAppDelegate() {
    PEMainWindowController* mainWindowCtrl;
}
@end

@implementation PEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[NSValueTransformer setValueTransformer:[[PEAlbumTypeImageTransformer alloc] init] forName:@"AlbumTypeImageTransformer"];

    mainWindowCtrl = [[PEMainWindowController alloc] init];
    [mainWindowCtrl window];
}

@end
