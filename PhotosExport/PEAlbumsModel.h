//
//  PEAlbumsModel.h
//  PhotosExport
//
//  Created by Steven Streeting on 20/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEAlbumNode;

// Notification raised by PEAlbumsModel to indicate new albums have been detected
// Raised wherever in the tree they have been updated
#define PE_NOTIFICATION_ALBUMS_PROGRESS @"albumsProgress"

// Notification raised by PEAlbumsModel to indicate all albums have been enumerated
#define PE_NOTIFICATION_ALBUMS_FINISHED @"albumsFinished"

@interface PEAlbumsModel : NSObject
@property (strong, nonatomic) NSMutableArray<PEAlbumNode*>* tree;

- (instancetype)init;
// Begin the load of albums asynchronously, be sure to listen to notifications
- (void)beginLoad;
@end
