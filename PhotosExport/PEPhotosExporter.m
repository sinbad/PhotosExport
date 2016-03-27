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
#import "PEAlbumObject.h"

@implementation PEPhotosExporter


+ (NSError*)exportPhotos:(PEAlbumsModel*)model toDir:(NSString*)dir
                callback:(BOOL (^)(NSString*, NSUInteger, NSUInteger, NSError*))callback {
    
    // First add up out what we're going to export for progress
    NSUInteger numPhotos, numVideos, totalBytes = 0;
    for (PEAlbumNode* n in model.tree) {
        [self recurseGetSize:n outNumPhotos:&numPhotos outNumVideos:&numVideos outTotalBytes:&totalBytes];
    }
    
    NSUInteger bytesDone = 0;
    for (PEAlbumNode* n in model.tree) {
        NSError* err = [self recurseExport:n rootDir:dir callback:callback bytesDone:&bytesDone totalBytes:totalBytes];
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
                bytesDone:(NSUInteger*)pBytesDone totalBytes:(NSUInteger)totalBytes
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
    for (PEAlbumObject* o in node.albumContents) {
        NSURL* url = o.url;
        if (![url startAccessingSecurityScopedResource])
            return [NSError errorWithDomain:@"PhotosExport"
                                       code:2
                                   userInfo:@{@"message": NSLocalizedString(@"DeniedAccessToPhotosURL", @"")}];
        
        NSString* filename = url.lastPathComponent;
		// Use name if present but make sure we append extension
		if (o.name) {
			filename = o.name;
			if ([[filename pathExtension] compare:[url pathExtension] options:NSCaseInsensitiveSearch] != NSOrderedSame) {
				filename = [filename stringByAppendingPathExtension:[url pathExtension]];
			}
		}
        NSString* fullpath = [dir stringByAppendingPathComponent:filename];
        BOOL copy = YES;
        BOOL overwrite = NO;
        NSMutableString* copyErrorString = [NSMutableString string];
        
        // Check for overwrite
        if ([fm fileExistsAtPath:fullpath]) {
            // Default to overwrite (in case we can't get attributes)
            overwrite = YES;
            NSDictionary<NSString*,id>* destattr = [fm attributesOfItemAtPath:fullpath error:nil];
            NSDictionary<NSString*,id>* srcattr = [fm attributesOfItemAtPath:url.path error:nil];
            
            if (destattr && srcattr) {
                if (destattr.fileSize == srcattr.fileSize &&
                    [destattr fileModificationDate] >= [srcattr fileModificationDate]) {
                    // File is fine as it is, no copy needed
                    copy = NO;
                    overwrite = NO;
                }
            }
        }

        // Check for missing source
        if (copy && ![fm fileExistsAtPath:url.path]) {
            // This can happen if using iCloud Photo Library & we do not have full res versions locally
            // Doesn't seem to be an API to download right now, Apple hasn't properly exposed
            // Photos.framework on OS X so [PHImageManager requestImageForAsset] isn't available
            // PITA Apple! We'll just have to skip
            copy = NO;
			if ([copyErrorString length])
				[copyErrorString appendString:@"\n"];
            [copyErrorString appendFormat:NSLocalizedString(@"ErrorMissingFile", @""), node.canonicalName, filename];
        }

        if (copy) {
            NSURL* destURL = [NSURL fileURLWithPath:fullpath];
            
            if (overwrite) {
				if (![fm removeItemAtURL:destURL error:&ferr]) {
					if ([copyErrorString length])
						[copyErrorString appendString:@"\n"];
                    [copyErrorString appendFormat:NSLocalizedString(@"ErrorReplacingFile", @""), fullpath, url.path, ferr.localizedDescription];
                }
			}
			
			if (![fm copyItemAtURL:url toURL:destURL error:&ferr]) {
				if ([copyErrorString length])
					[copyErrorString appendString:@"\n"];
				[copyErrorString appendFormat:NSLocalizedString(@"ErrorCopyingFile", @""), url.path, fullpath, ferr.localizedDescription];
			}
        }
        
        [url stopAccessingSecurityScopedResource];
        *pBytesDone += o.fileSize;
        // Report item in album format for progress
        NSString* progressItem = [node.canonicalName stringByAppendingPathComponent:filename];
		NSError* copyError = nil;
		if ([copyErrorString length]) {
			copyError = [NSError errorWithDomain:@"PhotosExport"
											code:4
										userInfo:@{@"message": copyErrorString}];
			
		}
        if (!callback(progressItem, *pBytesDone, totalBytes, copyError))
            return [NSError errorWithDomain:@"PhotosExport"
                                       code:99
                                   userInfo:@{@"message": NSLocalizedString(@"UserCancelledExport", @"")}];
    }
    
    for (PEAlbumNode* child in node.children) {
        NSError* err = [self recurseExport:child rootDir:rootDir callback:callback bytesDone:pBytesDone totalBytes:totalBytes];
        if (err)
            return err;
    }
    
    return nil;
}
@end
