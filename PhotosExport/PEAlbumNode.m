//
//  PEAlbumNode.m
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumNode.h"

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
          @"com.apple.Photos.FacesAlbum" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.LastImportGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.FavoritesGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.FrontCameraGroup" : @(PEAlbumTypeSystemSmart), // Selfies
          @"com.apple.Photos.PanoramasGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.VideosGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.SloMoGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.BurstGroup" : @(PEAlbumTypeSystemSmart),
          @"com.apple.Photos.Folder" : @(PEAlbumTypeFolder),
          @"com.apple.Photos.Album" : @(PEAlbumTypeAlbum),
          @"com.apple.Photos.SmartAlbum" : @(PEAlbumTypeUserSmart),
          };
        
        NSNumber* t = [typeMap objectForKey:group.typeIdentifier];
        if (t)
            self.albumType = [t integerValue];
        else
            self.albumType = PEAlbumTypeAlbum;
        
        NSLog(@"PEAlbumNode: %@ (type:%@)", self.name, self.mediaGroup.typeIdentifier);
        
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
    for(MLMediaObject* o in self.mediaGroup.mediaObjects)
    {
        switch(o.mediaType) {
            case MLMediaTypeImage:
                self.photoCount++;
                break;
            case MLMediaTypeMovie:
                self.videoCount++;
                break;
            default:
                continue; // should never happen
        }
        [self willChangeValueForKey:@"description"];
        self.totalBytes += o.fileSize;
        [self.albumContents addObject:o];
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

@end
