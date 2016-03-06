//
//  PEAlbumObject.h
//  PhotosExport
//
//  Created by Steven Streeting on 06/03/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

@import Foundation;
@import MediaLibrary;

typedef NS_ENUM(NSUInteger, PEObjectType)
{
    PEObjectTypeImage = 0,
    PEObjectTypeVideo = 1,
};

@interface PEAlbumObject : NSObject

@property (strong, nonatomic, readonly) MLMediaObject* mediaObject;
@property (copy, nonatomic, readonly) NSString* name;
@property (assign, nonatomic, readonly) PEObjectType objectType;
@property (assign, nonatomic, readonly) NSUInteger fileSize;
// Returns a valid URL, might be the same as originalUrl
@property (copy, nonatomic, readonly) NSURL* url;
// Unmodified asset url
@property (copy, nonatomic, readonly) NSURL* originalUrl;

+ (instancetype)objectWithMediaObject:(MLMediaObject*)o;
- (instancetype)initWithMediaObject:(MLMediaObject*)o;


@end
