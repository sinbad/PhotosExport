//
//  PEAlbumObject.m
//  PhotosExport
//
//  Created by Steven Streeting on 06/03/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumObject.h"

@implementation PEAlbumObject

+ (instancetype)objectWithMediaObject:(MLMediaObject*)o
{
    return [[PEAlbumObject alloc] initWithMediaObject:o];
}

- (instancetype)initWithMediaObject:(MLMediaObject*)o
{
    if (self = [super init]) {
        _mediaObject = o;
        switch(o.mediaType) {
            default:
            case MLMediaTypeImage:
                _objectType = PEObjectTypeImage;
                break;
            case MLMediaTypeMovie:
                _objectType = PEObjectTypeVideo;
                break;
        }
        _name = o.name;
        _url = o.URL;
        _originalUrl = o.originalURL;
        _fileSize = o.fileSize;
        
        NSFileManager* fm = [NSFileManager defaultManager];
        // Sometimes the URL points to a missing file, often when the fileSize is 0 too
        // Seems to be related to iCloud Photo Library but happens even when you have the
        // options set to download originals
        // Answer appears to be to use the originalUrl instead & get the fileSize from there
        BOOL usefallbackoriginal = NO;
        if (!_url || !_fileSize)
            usefallbackoriginal = YES;
        if (!usefallbackoriginal) {
            // Check actual file is present
            if ([_url startAccessingSecurityScopedResource]) {
                if (![fm fileExistsAtPath:[_url path]]) {
                    usefallbackoriginal = YES;
                }
                [_url stopAccessingSecurityScopedResource];
            } else {
                usefallbackoriginal = YES;
            }
        }
        
        if (usefallbackoriginal) {
            _url = _originalUrl;
            // Get actual file size
            if ([_url startAccessingSecurityScopedResource]) {
                NSDictionary<NSString*,id>* attr = [fm attributesOfItemAtPath:[_url path] error:nil];
                if (attr) {
                    _fileSize = [attr fileSize];
                }
                [_url stopAccessingSecurityScopedResource];
            }
        }
        
    }
    return self;
}


@end
