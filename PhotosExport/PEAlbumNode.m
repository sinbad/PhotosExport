//
//  PEAlbumNode.m
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

@import Cocoa;
#import "PEAlbumNode.h"
#import "PEAlbumObject.h"

@implementation PEAlbumNode

- (instancetype)initWithParent:(PEAlbumNode*)parent group:(MLMediaGroup*)group {
    if (self = [super init]) {
        self.mediaGroup = group;
        self.parent = parent;
        self.name = group.name;
        self.uniqueId = [group.attributes objectForKey:@"identifier"];
        self.canonicalName = parent? [parent.canonicalName stringByAppendingFormat:@"/%@", self.name] : self.name;
        self.children = [NSMutableArray array];
        
        NSDictionary<NSString*, NSNumber*>* typeMap =
        @{
          @"com.apple.Photos.FacesAlbum" : @(PEAlbumTypeFaces),
          @"com.apple.Photos.LastImportGroup" : @(PEAlbumTypeLastImport),
          @"com.apple.Photos.FavoritesGroup" : @(PEAlbumTypeFavourites),
          @"com.apple.Photos.FrontCameraGroup" : @(PEAlbumTypeSelfies),
          @"com.apple.Photos.PanoramasGroup" : @(PEAlbumTypePanoramas),
          @"com.apple.Photos.VideosGroup" : @(PEAlbumTypeVideos),
          @"com.apple.Photos.SloMoGroup" : @(PEAlbumTypeSloMo),
          @"com.apple.Photos.BurstGroup" : @(PEAlbumTypeBurst),
          @"com.apple.Photos.Folder" : @(PEAlbumTypeFolder),
          @"com.apple.Photos.Album" : @(PEAlbumTypeAlbum),
          @"com.apple.Photos.SmartAlbum" : @(PEAlbumTypeUserSmart),
          };
        
        // Special case Faces root (treat as a folder)
        if ([group.name isEqualToString:@"Faces"] && [group.typeIdentifier isEqualToString:@"com.apple.Photos.FacesAlbum"]) {
            self.albumType = PEAlbumTypeFolder;
        } else {
            NSNumber* t = [typeMap objectForKey:group.typeIdentifier];
            if (t)
                self.albumType = [t integerValue];
            else
                self.albumType = PEAlbumTypeAlbum;
        }
        //NSLog(@"PEAlbumNode: %@ (type:%@)", self.name, self.mediaGroup.typeIdentifier);
        
    }
    return self;
}

- (void)beginEnumerateItems {
    [self.mediaGroup addObserver:self
            forKeyPath:@"mediaObjects"
               options:0
               context:nil];
    self.albumContents = [NSMutableArray array];
    
    [self.mediaGroup mediaObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    // Only used for mediaObjects ready notification
    for(MLMediaObject* mediaObj in self.mediaGroup.mediaObjects)
    {
        PEAlbumObject* photoObj = [PEAlbumObject objectWithMediaObject:mediaObj];
        switch(photoObj.objectType) {
            case PEObjectTypeImage:
                self.photoCount++;
                break;
            case PEObjectTypeVideo:
                self.videoCount++;
                break;
            default:
                continue; // should never happen
        }
        [self willChangeValueForKey:@"description"];
        self.totalBytes += photoObj.fileSize;
        [self.albumContents addObject:photoObj];
        [self didChangeValueForKey:@"description"];
        //NSLog(@"%@ (url:%@ )(id:%@)", [self.canonicalName stringByAppendingFormat:@"/%@", o.name], o.URL.path, o.identifier);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PE_ALBUM_ENUMERATE_ITEMS_FINISHED object:self];
}

- (NSString *)description {
    NSMutableString* s = [NSMutableString stringWithString:self.name];
    if (self.photoCount || self.videoCount) {
        [s appendString:@" ("];
        if (self.photoCount)
            [s appendFormat:@"%ld photos", self.photoCount];
        if (self.videoCount) {
            if (self.photoCount)
                [s appendString:@", "];
            [s appendFormat:@"%ld videos", self.videoCount];
        }
        [s appendFormat:@", %@)", [NSByteCountFormatter stringFromByteCount:self.totalBytes countStyle:NSByteCountFormatterCountStyleFile]];
    }
    return s;
}

- (void)checkChildCheckState {
    BOOL allChecked = YES;
    BOOL allUnchecked = YES;
    for (PEAlbumNode* child in self.children) {
        switch (child.checkState) {
            case NSOffState:
                allChecked = NO;
                break;
            case NSOnState:
            case NSMixedState:
                allUnchecked = NO;
                break;
        }
    }
    NSInteger newState = _checkState;
    // Don't want to trigger property here because we only propagate upwards
    if (allChecked)
        newState = NSOnState;
    else if (allUnchecked)
        newState = NSOffState;
    else
        newState = NSMixedState;
    
    if (newState != _checkState) {
        [self willChangeValueForKey:@"checkState"];
        _checkState = newState;
        [self didChangeValueForKey:@"checkState"];
        if (self.parent)
            [self.parent checkChildCheckState];
    }
    
}

- (void)checkStateOverride:(NSNumber*)c {
    self.checkState = [c integerValue];
}
- (void)setCheckState:(NSInteger)c {
    if (c == NSMixedState) {
        // Can't be mixed from outside, only internally
        return;
    }
    _checkState = c;
    
    // Tell parent
    if (self.parent)
        [self.parent checkChildCheckState];
    
    // Propagate to children
    for (PEAlbumNode* child in self.children)
        [child setCheckStateFromParent:_checkState];
        
}

- (void)setCheckStateFromParent:(NSInteger)c {
    // Don't want to trigger property here because we only propagate upwards
    if (c != _checkState) {
        [self willChangeValueForKey:@"checkState"];
        _checkState = c;
        [self didChangeValueForKey:@"checkState"];
        
        // Propagate to children
        for (PEAlbumNode* child in self.children)
            child.checkState = _checkState;

    }
}
@end
