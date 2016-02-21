//
//  PEPhotosExporter.m
//  PhotosExport
//
//  Created by Steven Streeting on 21/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

@import Cocoa;
#import "PEPhotosExporter.h"
#import "PEAlbumsModel.h"
#import "PEAlbumNode.h"

@implementation PEPhotosExporter


+ (NSError*)exportPhotos:(PEAlbumsModel*)model toDir:(NSString*)dir {
    
    for (PEAlbumNode* n in model.tree) {
        NSError* err = [self recursePhotos:n rootDir:dir];
        if (err)
            return err;
    }
    return nil;
}

+ (NSError*)recursePhotos:(PEAlbumNode*)node rootDir:(NSString*)rootDir {
    // Skip & don't recurse into off nodes
    if (node.checkState == NSOffState)
        return nil;
    
    // Create folder if doesn't exist
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* dir = [rootDir stringByAppendingPathComponent:node.canonicalName];
    BOOL isDir = NO;
    NSError* ferr = nil;
    if (!([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir)) {
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&ferr];
        if (ferr != nil) {
            return ferr;
        }
    }
    for (MLMediaObject* o in node.albumContents) {
        NSURL* url = o.URL;
        if (![url startAccessingSecurityScopedResource])
            return [NSError errorWithDomain:@"PhotosExport"
                                       code:2
                                   userInfo:@{@"messageCode": @"DeniedAccessToPhotosURL"}];
        
        NSString* filename = o.name ? o.name : url.lastPathComponent;
        NSString* fullpath = [dir stringByAppendingPathComponent:filename];
        NSURL* destURL = [NSURL fileURLWithPath:fullpath];
        
        if (![fm copyItemAtURL:url toURL:destURL error:&ferr]) {
            [url stopAccessingSecurityScopedResource];
            return [NSError errorWithDomain:@"PhotosExport"
                                       code:2
                                   userInfo:@{@"messageCode": @"ErrorCopyingFile",
                                              @"messageArgs": @[url.path, fullpath, ferr.description]}];
            
        }
        [url stopAccessingSecurityScopedResource];
    }
    
    for (PEAlbumNode* child in node.children) {
        NSError* err = [self recursePhotos:child rootDir:rootDir];
        if (err)
            return err;
    }
    
    return nil;
}
@end
