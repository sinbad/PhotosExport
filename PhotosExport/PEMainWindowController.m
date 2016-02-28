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
    BOOL exportCancelRequested;
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
- (IBAction)checkboxClicked:(id)sender {
    NSButton* b = sender;
    // Automatically click again if setting to mixed, don't allow this from user input
    if([b state] == NSMixedState) {
        [[sender selectedCell] performClick:sender];
        return;
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
        
        // Begin progress sheet
        [self.window beginSheet:self.exportProgressWindow completionHandler:^(NSModalResponse returnCode) {
            [self.exportProgressWindow orderOut:self];
        }];
        
        // export in a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError* err = [PEPhotosExporter exportPhotos:model toDir:panel.directoryURL.path callback:^BOOL(NSString *nextItem, NSUInteger bytesDone, NSUInteger totalBytes) {
                return [self updateExportProgress:nextItem bytesDone:bytesDone totalBytes:totalBytes];
            }];
            // Back to main queue for error/success processing
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.window endSheet:self.exportProgressWindow returnCode:err ? NSModalResponseCancel : NSModalResponseOK];
                if (err) {
                    NSAlert* alert = [[NSAlert alloc] init];
                    alert.alertStyle = NSCriticalAlertStyle;
                    alert.messageText = NSLocalizedString(@"ErrorDuringExport", @"");
                    if ([err.domain isEqualToString:@"PhotosExport"]) {
                        alert.informativeText = [err.userInfo objectForKey:@"message"];
                        
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
            });
            
        });
    }
}

- (BOOL)updateExportProgress:(NSString*)progressItem bytesDone:(NSUInteger)bytesDone totalBytes:(NSUInteger)totalBytes {
    // Called in a background thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.exportProgressItem = progressItem;
        self.exportProgressBytesDone = bytesDone;
        self.exportProgressTotalBytes = totalBytes;
        self.exportProgressSizeDesc = [NSString stringWithFormat:@"%@ / %@",
                                       [NSByteCountFormatter stringFromByteCount:bytesDone countStyle:NSByteCountFormatterCountStyleFile],
                                       [NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile]];
    });
    
    // This is a background thread but don't bother locking, single transition &
    // 100% integrity not needed
    return !exportCancelRequested;
}

- (IBAction)cancelExport:(id)sender {
    // No lock needed, single transition flag
    exportCancelRequested = YES;
}

@end
