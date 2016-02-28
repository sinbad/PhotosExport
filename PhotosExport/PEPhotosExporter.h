//
//  PEPhotosExporter.h
//  PhotosExport
//
//  Created by Steven Streeting on 21/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEAlbumsModel;

@interface PEPhotosExporter : NSObject

// Export model with selected items to dir
// Returns NSError if the export was interrupted for any reason;
// non-fatal errors are received by the callback
+ (NSError*)exportPhotos:(PEAlbumsModel*)model toDir:(NSString*)dir
                callback:(BOOL (^)(NSString* nextItem, NSUInteger bytesDone, NSUInteger totalBytes, NSError* nonFatalError))callback;
@end
