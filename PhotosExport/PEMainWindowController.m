//
//  PEMainWindowController.m
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEMainWindowController.h"
#import "PEAlbumsModel.h"
#import "PEAlbumNode.h"


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
    
    self.loadingAlbums = YES;
    [model beginLoad];
}

- (void)albumsUpdated:(NSNotification*)notif {
    [self.outlineView reloadData];
}
- (void)albumsFinished:(NSNotification*)notif {
    [self.outlineView reloadData];
    self.loadingAlbums = NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    PEAlbumNode* node = item;
    return node.children.count > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item) {
        PEAlbumNode* node = item;
        return node.children.count;
    } else {
        return model.tree.count;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item) {
        PEAlbumNode* node = item;
        return node.children[index];
    } else {
        return model.tree[index];
    }
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}
@end
