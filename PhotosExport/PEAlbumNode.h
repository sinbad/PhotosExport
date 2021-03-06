//
//  PEAlbumNode.h
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MediaLibrary;

@class PEAlbumObject;

typedef NS_ENUM(NSUInteger, PEAlbumType)
{
    // A regular album
    PEAlbumTypeAlbum = 0,
    // Group folder (no items)
    PEAlbumTypeFolder = 1,
    // Smart Album (user created)
    PEAlbumTypeUserSmart = 2,
    // Faces, Selfies, Last Import etc - all default ignore
    PEAlbumTypeFaces = 3,
	PEAlbumTypeVideos = 4,
	PEAlbumTypeSelfies = 5,
	PEAlbumTypeLastImport = 6,
	PEAlbumTypePanoramas = 7,
	PEAlbumTypeFavourites = 8,
	PEAlbumTypeSloMo = 9,
	PEAlbumTypeBurst = 10,
	PEAlbumTypeScreenshots = 11,
	PEAlbumTypeAllPhotos = 99
};

// Notification that item enumeration (beginEnumerateItems) has finished
#define PE_ALBUM_ENUMERATE_ITEMS_FINISHED @"albumItemsFinished"

@interface PEAlbumNode : NSObject

@property (weak, nonatomic) PEAlbumNode* parent;
@property (strong, nonatomic) NSMutableArray<PEAlbumNode*>* children;
@property (assign, nonatomic) PEAlbumType albumType;
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* uniqueId;
@property (copy, nonatomic) NSString* canonicalName; // name with full path leading to it
@property (assign, nonatomic) NSInteger checkState; // tri-state (mixed if only some children checked)
@property (strong, nonatomic) MLMediaGroup* mediaGroup;
// These items won't be up to date until beginEnumerateItems has finished
@property (assign, nonatomic) NSUInteger photoCount;
@property (assign, nonatomic) NSUInteger videoCount;
@property (assign, nonatomic) NSUInteger totalBytes;
@property (readonly, nonatomic) NSString* contentSummary;
// The actual items contained
@property (strong, nonatomic) NSMutableArray<PEAlbumObject*>* albumContents;

- (instancetype)initWithParent:(PEAlbumNode*)parent group:(MLMediaGroup*)group;
// Asynchronously enumerate the items (photos, videos) in the album
- (void)beginEnumerateItems;
@end
