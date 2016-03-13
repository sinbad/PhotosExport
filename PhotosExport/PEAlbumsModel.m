//
//  PEAlbumsModel.m
//  PhotosExport
//
//  Created by Steven Streeting on 20/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumsModel.h"
#import "PEAlbumNode.h"
@import MediaLibrary;
@import Cocoa;

@interface PEAlbumsModel() {
    MLMediaLibrary* mediaLibrary;
    MLMediaSource *mediaSource;
    NSUInteger nodesEnumerating;
    NSDictionary<NSString*,NSNumber*>* selections;
}
@end

@implementation PEAlbumsModel

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *options = @{
                                  MLMediaLoadSourceTypesKey: @(MLMediaSourceTypeImage),
                                  MLMediaLoadIncludeSourcesKey: @[MLMediaSourcePhotosIdentifier]
                                  };
        mediaLibrary = [[MLMediaLibrary alloc] initWithOptions:options];
    }
    return self;
}

- (void)beginLoad:(NSDictionary<NSString*,NSNumber*>*)defaultSelections {
    [mediaLibrary addObserver:self forKeyPath:@"mediaSources" options:0 context:(__bridge void *)mediaLibrary];
    self.tree = [NSMutableArray array];
    selections = defaultSelections;
    nodesEnumerating = 0;
    // This starts async loading
    [mediaLibrary mediaSources];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == (__bridge void *)mediaLibrary) {
        mediaSource = [mediaLibrary.mediaSources objectForKey:MLMediaSourcePhotosIdentifier];
        
        [mediaSource addObserver:self
                      forKeyPath:@"rootMediaGroup"
                         options:0
                         context:(__bridge void *)mediaSource];
        
        [mediaSource rootMediaGroup];
    }
    else if (context == (__bridge void *)mediaSource)
    {
        MLMediaGroup *albums = [mediaSource mediaGroupForIdentifier:@"TopLevelAlbums"];
        
        [self recurseGroup:albums];
    }
}

- (void)recurseGroup:(MLMediaGroup*)group {
    [self recurseGroup:group parentNode:nil];
}

- (void)initSelectionForNode:(PEAlbumNode*)n {
    NSNumber* saved = [selections objectForKey:n.canonicalName];
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
}

- (void)recurseGroup:(MLMediaGroup*)group parentNode:(PEAlbumNode*)parent {
    PEAlbumNode* newNode = nil;
    
    // Don't include root albums group, start at next level down
    if (![group.typeIdentifier isEqualToString:@"com.apple.Photos.AlbumsGroup"])
    {
        newNode = [[PEAlbumNode alloc] initWithParent:parent group:group];
        [self initSelectionForNode:newNode];
        
        if (!parent)
            [self.tree addObject:newNode];
        else
            [parent.children addObject:newNode];
        
        // Enumerate objects if it's not a folder (which have no items)
        if (newNode.albumType != PEAlbumTypeFolder) {
            nodesEnumerating++;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeEnumerated:) name:PE_ALBUM_ENUMERATE_ITEMS_FINISHED object:newNode];
            [newNode beginEnumerateItems];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:PE_NOTIFICATION_ALBUMS_PROGRESS object:self];
    }
    
    for (MLMediaGroup *subgroup in group.childGroups) {
        [self recurseGroup:subgroup parentNode:newNode];
    }
}

- (void)nodeEnumerated:(NSNotification*)notif {
    nodesEnumerating--;
    if (!nodesEnumerating) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PE_NOTIFICATION_ALBUMS_FINISHED object:self];
    }
}




@end
