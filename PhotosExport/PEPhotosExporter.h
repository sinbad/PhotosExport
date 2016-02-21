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
+ (NSError*)exportPhotos:(PEAlbumsModel*)model toDir:(NSString*)dir;
@end
