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
#import "PEPhotosExporter.h"

@interface PEMainWindowController () {
    PEAlbumsModel* model;
    NSDictionary<NSString*, NSNumber*>* storedSelections;
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
    [self loadOrDefaultSelection];
    [self.outlineView reloadData];
    [self expandDefaults];
}
- (void)albumsFinished:(NSNotification*)notif {
    [self loadOrDefaultSelection];
    [self.outlineView reloadData];
    self.loadingAlbums = NO;
    [self expandDefaults];
}

- (NSDictionary<NSString*, NSNumber*>*)defaultSelections {
    if (!storedSelections) {
        // TODO load from last selection to override
        storedSelections = @{};
    }
    
    
    return storedSelections;
}

- (void)loadOrDefaultSelection {
    NSDictionary<NSString*, NSNumber*>* sel = [self defaultSelections];
    for (PEAlbumNode* n in model.tree) {
        [self recurseSetSelectionOnNode:n fromState:sel];
    }
}

- (void)recurseSetSelectionOnNode:(PEAlbumNode*)n fromState:(NSDictionary<NSString*, NSNumber*>*)sel {
    
    NSNumber* saved = [sel objectForKey:n.canonicalName];
    if (saved) {
        n.checkState = [saved integerValue];
    } else {
        // default by album type; default check proper albums & folders, ignore smart filters
        switch (n.albumType) {
            case PEAlbumTypeAlbum:
            case PEAlbumTypeFolder:
                n.checkState = NSOnState;
                break;
            default:
                n.checkState = NSOffState;
                break;
        }
    }
    
    for (PEAlbumNode* child in n.children) {
        [self recurseSetSelectionOnNode:child fromState:sel];
    }
}
- (void)saveSelection {
    // Save state for all nodes, including off state
    // nodes for which no state is loaded will be defaulted

    // TODO

}
- (void)expandDefaults {
    for (PEAlbumNode* node in model.tree) {
        [self recurseExpandDefaults:node];
    }
}

- (void)recurseExpandDefaults:(PEAlbumNode*)n {
    if (n.checkState != NSOffState) {
        [self.outlineView expandItem:n];
        
        for (PEAlbumNode* child in n.children) {
            [self recurseExpandDefaults:child];
        }
    }
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

- (IBAction)export:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    [panel setAllowsMultipleSelection:NO];
    panel.title = NSLocalizedString(@"ExportPanelTitle", @"");
    panel.message = NSLocalizedString(@"ExportPanelMessage", @"");
    NSInteger res = [panel runModal];
    if (res == NSFileHandlingPanelOKButton) {
        NSError* err = [PEPhotosExporter exportPhotos:model toDir:panel.directoryURL.path];
        if (err) {
            NSAlert* alert = [[NSAlert alloc] init];
            alert.alertStyle = NSCriticalAlertStyle;
            alert.messageText = NSLocalizedString(@"ErrorDuringExport", @"");
            if ([err.domain isEqualToString:@"PhotosExport"]) {
                NSString* msgCode = [err.userInfo objectForKey:@"messageCode"];
                NSArray* msgArgs = [err.userInfo objectForKey:@"messageArgs"];
                if (msgArgs)
                    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(msgCode, @""), msgArgs];
                else
                    alert.informativeText = NSLocalizedString(msgCode, @"");
        
            } else {
                alert.informativeText = [err description];
            }
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
        } else {
            NSAlert* alert = [[NSAlert alloc] init];
            alert.alertStyle = NSInformationalAlertStyle;
            alert.messageText = NSLocalizedString(@"ExportedOKTitle", @"");
            alert.informativeText = NSLocalizedString(@"ExportedOKMsg", @"");
            [alert addButtonWithTitle:@"OK"];
            [alert addButtonWithTitle:NSLocalizedString(@"ShowInFinder", @"")];
            if ([alert runModal] == NSAlertSecondButtonReturn) {
                [[NSWorkspace sharedWorkspace] selectFile:panel.directoryURL.path inFileViewerRootedAtPath:panel.directoryURL.path];
            }
        }
    }
    
    
}
@end
