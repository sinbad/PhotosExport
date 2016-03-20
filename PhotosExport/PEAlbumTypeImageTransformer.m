//
//  PEAlbumTypeImageTransformer.m
//  PhotosExport
//
//  Created by Steven Streeting on 20/03/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumTypeImageTransformer.h"
#import "PEAlbumNode.h"
@import Cocoa;

@implementation PEAlbumTypeImageTransformer

+ (Class)transformedValueClass {
	return [NSImage self];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)value {
	if (!value)
		return nil;
	PEAlbumNode* n = value;
	switch (n.albumType) {
		default:
		case PEAlbumTypeAlbum:
			return [NSImage imageNamed:@"PhotoAlbum"];
		case PEAlbumTypeFolder:
			return [NSImage imageNamed:NSImageNameFolder];
		case PEAlbumTypeFaces:
			return [NSImage imageNamed:NSImageNameUser];
		case PEAlbumTypeVideos:
			return [NSImage imageNamed:@"VideoCamera"];
		case PEAlbumTypeLastImport:
			return [NSImage imageNamed:@"Import"];
		case PEAlbumTypeFavourites:
			return [NSImage imageNamed:@"Heart"];
		case PEAlbumTypeBurst:
			return [NSImage imageNamed:@"Burst"];
		case PEAlbumTypePanoramas:
			return [NSImage imageNamed:@"Panorama"];
		case PEAlbumTypeSelfies:
			return [NSImage imageNamed:NSImageNameUser];
		case PEAlbumTypeScreenshots:
			return [NSImage imageNamed:@"Screenshots"];
		case PEAlbumTypeSloMo:
			return [NSImage imageNamed:@"Stopwatch"];
			
			
		case PEAlbumTypeUserSmart:
			return [NSImage imageNamed:NSImageNameActionTemplate];
	}
}


@end
