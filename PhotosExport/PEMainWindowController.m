//
//  PEMainWindowController.m
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEMainWindowController.h"
#import "PEAlbumsModel.h"
@interface PEMainWindowController () {
    PEAlbumsModel* model;
}
@end

@implementation PEMainWindowController

- (instancetype)init {
    if (self = [super initWithWindowNibName:@"PEMainWindowController"]) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    model = [[PEAlbumsModel alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsUpdated:) name:PE_NOTIFICATION_ALBUMS_PROGRESS object:model];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsFinished:) name:PE_NOTIFICATION_ALBUMS_FINISHED object:model];
    
    [model beginLoad];
}

- (void)albumsUpdated:(NSNotification*)notif {
    
}
- (void)albumsFinished:(NSNotification*)notif {
    
}

@end
