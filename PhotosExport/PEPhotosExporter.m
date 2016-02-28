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


+ (NSError*)exportPhotos:(PEAlbumsModel*)model toDir:(NSString*)dir
                callback:(BOOL (^)(NSString*, NSUInteger, NSUInteger, NSError*))callback {
    
    // First add up out what we're going to export for progress
    NSUInteger numPhotos, numVideos, totalBytes = 0;
    for (PEAlbumNode* n in model.tree) {
        [self recurseGetSize:n outNumPhotos:&numPhotos outNumVideos:&numVideos outTotalBytes:&totalBytes];
    }
    
    for (PEAlbumNode* n in model.tree) {
        NSError* err = [self recurseExport:n rootDir:dir callback:callback bytesDone:0 totalBytes:totalBytes];
        if (err)
            return err;
    }
    return nil;
}

+ (void)recurseGetSize:(PEAlbumNode*)node outNumPhotos:(NSUInteger*)numPhotos outNumVideos:(NSUInteger*)numVideos outTotalBytes:(NSUInteger*)totalBytes {

    // Skip & don't recurse into off nodes
    if (node.checkState == NSOffState)
        return;

    *numPhotos += node.photoCount;
    *numVideos += node.videoCount;
    *totalBytes += node.totalBytes;
    
    for (PEAlbumNode* child in node.children) {
        [self recurseGetSize:child outNumPhotos:numPhotos outNumVideos:numVideos outTotalBytes:totalBytes];
    }

    
}

+ (NSError*)recurseExport:(PEAlbumNode*)node rootDir:(NSString*)rootDir
                 callback:(BOOL (^)(NSString*, NSUInteger, NSUInteger, NSError*))callback
                bytesDone:(NSUInteger)bytesDone totalBytes:(NSUInteger)totalBytes
{
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
                                   userInfo:@{@"message": NSLocalizedString(@"DeniedAccessToPhotosURL", @"")}];
        
        NSString* filename = o.name ? o.name : url.lastPathComponent;
        NSString* fullpath = [dir stringByAppendingPathComponent:filename];
        NSURL* destURL = [NSURL fileURLWithPath:fullpath];
        
        // Report item in album format for progress
        NSString* progressItem = [node.canonicalName stringByAppendingPathComponent:filename];
        
        NSError* copyError = nil;
        
        if (![fm copyItemAtURL:url toURL:destURL error:&ferr]) {
            copyError = [NSError errorWithDomain:@"PhotosExport"
                                            code:4
                                        userInfo:@{@"message": [NSString stringWithFormat:NSLocalizedString(@"ErrorCopyingFile", @""), url.path, fullpath, ferr.localizedDescription]}];
        }
        [url stopAccessingSecurityScopedResource];
        bytesDone += o.fileSize;
        if (!callback(progressItem, bytesDone, totalBytes, copyError))
            return [NSError errorWithDomain:@"PhotosExport"
                                       code:99
                                   userInfo:@{@"message": NSLocalizedString(@"UserCancelledExport", @"")}];
    }
    
    for (PEAlbumNode* child in node.children) {
        NSError* err = [self recurseExport:child rootDir:rootDir callback:callback bytesDone:bytesDone totalBytes:totalBytes];
        if (err)
            return err;
    }
    
    return nil;
}
@end
