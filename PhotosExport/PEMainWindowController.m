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

#define PE_SAVED_SELECTIONS @"savedSelections"
#define PE_SAVED_EXPORTFOLDER @"savedExportFolder"

@interface PEMainWindowController () {
    PEAlbumsModel* model;
    NSDictionary<NSString*, NSNumber*>* storedSelections;
    BOOL exportCancelRequested;
    NSUInteger nonFatalErrorDuringExportCount;
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
	[self updateSelectedSummary];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsUpdated:) name:PE_NOTIFICATION_ALBUMS_PROGRESS object:model];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumsFinished:) name:PE_NOTIFICATION_ALBUMS_FINISHED object:model];
    
    self.loadingAlbums = YES;
    [model beginLoad:[self defaultSelections]];
}

- (void)albumsUpdated:(NSNotification*)notif {
    [self.outlineView reloadData];
    [self expandDefaults];
	[self updateSelectedSummary];
}
- (void)albumsFinished:(NSNotification*)notif {
    [self.outlineView reloadData];
    self.loadingAlbums = NO;
	[self updateSelectedSummary];
}

- (NSDictionary<NSString*, NSNumber*>*)defaultSelections {
    if (!storedSelections) {
        storedSelections = [[NSUserDefaults standardUserDefaults] dictionaryForKey:PE_SAVED_SELECTIONS];
    }
    if (!storedSelections) {
        storedSelections = @{};
    }
    
    return storedSelections;
}

- (IBAction)checkboxClicked:(id)sender {
    NSButton* b = sender;
    // Automatically click again if setting to mixed, don't allow this from user input
    if([b state] == NSMixedState) {
        [[sender selectedCell] performClick:sender];
		return;
    }
	
	NSRect brect = [b frame];
	NSPoint bpoint = NSMakePoint(NSMinX(brect), NSMinY(brect));
	NSPoint tpoint = [self.outlineView convertPoint:bpoint fromView:b];
	NSInteger r = [self.outlineView rowAtPoint:tpoint];
	
	[self updateSelectedRowCheckboxState:[b state] clickedRow:r];
	[self updateSelectedSummary];
}

- (void)updateSelectedRowCheckboxState:(NSUInteger)tostate clickedRow:(NSInteger)clickedRow {
    NSIndexSet* s = [self.outlineView selectedRowIndexes];
	if ([s containsIndex:clickedRow]) {
		[s enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			PEAlbumNode* n = [self.outlineView itemAtRow:idx];
			if (n.checkState != tostate)
				n.checkState = tostate;
		}];
	}
}

- (void)updateSelectedSummary {
	[self willChangeValueForKey:@"selectedSummary"];
	__block NSUInteger photoCount = 0, videoCount = 0, totalBytes = 0;
	for (PEAlbumNode* n in model.tree) {
		[self recurseSelected:n callback:^(PEAlbumNode* selNode) {
			if (selNode.albumType != PEAlbumTypeFolder) {
				photoCount += selNode.photoCount;
				videoCount += selNode.videoCount;
				totalBytes += selNode.totalBytes;
			}
		}];
	}
	_selectedSummary = [NSString stringWithFormat:NSLocalizedString(@"SelectedSummary", @""), photoCount, videoCount, [NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile]];
	[self didChangeValueForKey:@"selectedSummary"];
}

- (void)recurseSelected:(PEAlbumNode*)n callback:(void (^)(PEAlbumNode*))callback {
	
	if (n.checkState != NSOffState) {
		callback(n);
		for (PEAlbumNode* child in n.children) {
			[self recurseSelected:child callback:callback];
		}
	}
}

- (void)saveSelection {
    // Save state for all nodes, including off state
    // nodes for which no state is loaded will be defaulted
    NSMutableDictionary<NSString*, NSNumber*>* d = [NSMutableDictionary dictionaryWithCapacity:storedSelections.count];
    for (PEAlbumNode* n in model.tree) {
        [self recurseSaveSelection:n toState:d];
    }
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:PE_SAVED_SELECTIONS];
}

- (void)recurseSaveSelection:(PEAlbumNode*)n toState:(NSMutableDictionary<NSString*, NSNumber*>*)state {
    
    // Save on and off state so that only unknown items are defaulted
    [state setObject:@(n.checkState) forKey:n.canonicalName];
    
    for (PEAlbumNode* child in n.children) {
        [self recurseSaveSelection:child toState:state];
    }
    
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
    } else {
        [self.outlineView collapseItem:n collapseChildren:YES];
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

-(BOOL)outlineView:(NSOutlineView*)outlineView keyDown:(NSEvent*)e
{
	// toggle checkbox on space
	if ([e.characters characterAtIndex:0] == ' ')
	{
		NSIndexSet* s = [self.outlineView selectedRowIndexes];
		// Change all to the opposite of the first item
		PEAlbumNode* first = [self.outlineView itemAtRow:[s firstIndex]];
		NSInteger newState = first.checkState == NSOnState? NSOffState : NSOnState;
		[s enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
			PEAlbumNode* n = [self.outlineView itemAtRow:idx];
			if (n.checkState != newState)
				n.checkState = newState;
		}];
		[self updateSelectedSummary];
	}
	return NO; // continue to chain
	
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.exportProgressTable && row <= [self.exportMessageList count]) {
        return self.exportMessageList[row];
    }
    return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.exportProgressTable) {
        return [self.exportMessageList count];
    }
    return 0;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 17;
}

- (BOOL)checkDuplications {
	
	BOOL exportingAllPhotos = NO;
	BOOL exportingOthers = NO;
	for (PEAlbumNode* n in model.tree) {
		if (n.albumType == PEAlbumTypeAllPhotos) {
			if (n.checkState == NSOnState)
				exportingAllPhotos = YES;
		} else if (n.checkState != NSOffState) {
			exportingOthers = YES;
		}
	}
	if (exportingAllPhotos && exportingOthers) {
		NSAlert* alert = [[NSAlert alloc] init];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.messageText = NSLocalizedString(@"ExportingAllPhotosAndOthersTitle", @"");
		alert.informativeText = NSLocalizedString(@"ExportingAllPhotosAndOthersMsg", @"");
		[alert addButtonWithTitle:NSLocalizedString(@"ContinueWithDuplicates", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		return [alert runModal] == NSAlertFirstButtonReturn;
	}
	return YES;
}

- (IBAction)export:(id)sender
{
	if (![self checkDuplications])
		return;

	[self saveSelection];
	
	NSString* prevFolder = [[NSUserDefaults standardUserDefaults] stringForKey:PE_SAVED_EXPORTFOLDER];
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    [panel setAllowsMultipleSelection:NO];
    panel.title = NSLocalizedString(@"ExportPanelTitle", @"");
    panel.message = NSLocalizedString(@"ExportPanelMessage", @"");
    panel.prompt = NSLocalizedString(@"Export", @"");
	if ([prevFolder length])
		panel.directoryURL = [NSURL fileURLWithPath:prevFolder];
	
    NSInteger res = [panel runModal];
    if (res == NSFileHandlingPanelOKButton) {
        // reset
        nonFatalErrorDuringExportCount = 0;
        self.exportMessageList = [NSMutableArray arrayWithObject:NSLocalizedString(@"Exporting...", @"")];
        [self.exportProgressTable reloadData];
        self.exportProgressAbortHidden = NO;
        self.exportProgressCloseHidden = YES;
        exportCancelRequested = NO;
        // Begin progress sheet
        [self.window beginSheet:self.exportProgressWindow completionHandler:^(NSModalResponse returnCode) {
            [self.exportProgressWindow orderOut:self];
        }];
		
		[[NSUserDefaults standardUserDefaults] setValue:panel.directoryURL.path forKey:PE_SAVED_EXPORTFOLDER];
        // export in a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSError* err = nil;
			@try {
				err = [PEPhotosExporter exportPhotos:model toDir:panel.directoryURL.path callback:^BOOL(NSString *nextItem, NSUInteger bytesDone, NSUInteger totalBytes, NSError* nonFatalError) {
					return [self updateExportProgress:nextItem bytesDone:bytesDone totalBytes:totalBytes error:nonFatalError];
				}];
			} @catch (NSException *exception) {
				err = [NSError errorWithDomain:@"PhotosExport"
									code:9
								userInfo:@{@"message": [exception reason]}];
			} @finally {
				// Back to main queue for error/success processing
				dispatch_async(dispatch_get_main_queue(), ^{
					if (!err && nonFatalErrorDuringExportCount == 0) {
						[self.window endSheet:self.exportProgressWindow returnCode:NSModalResponseOK];
					}
					if (err) {
						self.exportProgressAbortHidden = YES;
						self.exportProgressCloseHidden = NO;
						NSAlert* alert = [[NSAlert alloc] init];
						alert.alertStyle = NSCriticalAlertStyle;
						alert.messageText = NSLocalizedString(@"ErrorDuringExport", @"");
						if ([err.domain isEqualToString:@"PhotosExport"]) {
							alert.informativeText = [err.userInfo objectForKey:@"message"];
							
						} else {
							alert.informativeText = [err localizedDescription];
						}
						[alert addButtonWithTitle:@"OK"];
						[alert runModal];
					} else if (nonFatalErrorDuringExportCount > 0) {
						self.exportProgressAbortHidden = YES;
						self.exportProgressCloseHidden = NO;
						NSAlert* alert = [[NSAlert alloc] init];
						alert.alertStyle = NSInformationalAlertStyle;
						alert.messageText = NSLocalizedString(@"ExportedWithErrorsTitle", @"");
						alert.informativeText = NSLocalizedString(@"ExportedWithErrorsMsg", @"");
						[alert addButtonWithTitle:@"OK"];
						[alert addButtonWithTitle:NSLocalizedString(@"ShowInFinder", @"")];
						if ([alert runModal] == NSAlertSecondButtonReturn) {
							[[NSWorkspace sharedWorkspace] selectFile:panel.directoryURL.path inFileViewerRootedAtPath:panel.directoryURL.path];
						}
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
					self.exportMessageList[[self.exportMessageList count]] = NSLocalizedString(@"Done.", @"");
					[self.exportProgressTable reloadData];
				});
			}
        });
    }
}

- (BOOL)updateExportProgress:(NSString*)progressItem bytesDone:(NSUInteger)bytesDone totalBytes:(NSUInteger)totalBytes error:(NSError*)nonFatalError {
    // Called in a background thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (nonFatalError) {
            nonFatalErrorDuringExportCount++;
            NSString* msg = nil;
            if ([nonFatalError.domain isEqualToString:@"PhotosExport"]) {
                msg = [nonFatalError.userInfo objectForKey:@"message"];
            } else {
                msg = [nonFatalError description];
            }
            self.exportMessageList[[self.exportMessageList count]-1] = msg;
            NSLog(@"%@", msg);
            [self.exportMessageList addObject:NSLocalizedString(@"Exporting...", @"")];
        } else {
            self.exportMessageList[[self.exportMessageList count]-1] = progressItem;
        }
        self.exportProgressBytesDone = bytesDone;
        self.exportProgressTotalBytes = totalBytes;
        self.exportProgressSizeDesc = [NSString stringWithFormat:@"%@ / %@",
                                       [NSByteCountFormatter stringFromByteCount:bytesDone countStyle:NSByteCountFormatterCountStyleFile],
                                       [NSByteCountFormatter stringFromByteCount:totalBytes countStyle:NSByteCountFormatterCountStyleFile]];
        [self.exportProgressTable reloadData];
    });
    
    // This is a background thread but don't bother locking, single transition &
    // 100% integrity not needed
    return !exportCancelRequested;
}

- (IBAction)cancelExport:(id)sender {
    // No lock needed, single transition flag
    exportCancelRequested = YES;
}

- (IBAction)closeExport:(id)sender {
    // only clickable if export finished with errors
    [self.window endSheet:self.exportProgressWindow returnCode:NSModalResponseOK];
}

- (void)windowWillClose:(NSNotification *)notification {
    // Save selection on close too in case changed & not exported
    [self saveSelection];
}


@end
