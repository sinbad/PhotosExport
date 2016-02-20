//
//  PEAlbumNode.m
//  PhotosExport
//
//  Created by Steven Streeting on 19/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumNode.h"

@implementation PEAlbumNode

- (instancetype)initWithParent:(PEAlbumNode*)parent group:(MLMediaGroup*)group {
    if (self = [super init]) {
        self.mediaGroup = group;
        self.parent = parent;
        self.name = group.name;
        self.uniqueId = [group.attributes objectForKey:@"identifier"];
        self.canonicalName = parent? [parent.canonicalName stringByAppendingFormat:@"/%@", self.name] : self.name;
        
        NSLog(@"PEAlbumNode: name=%@ id=%@", self.canonicalName, self.uniqueId);
    }
    return self;
}

@end
