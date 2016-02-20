//
//  PEAlbumsModel.m
//  PhotosExport
//
//  Created by Steven Streeting on 20/02/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEAlbumsModel.h"
#import "PEAlbumNode.h"
@import MediaLibrary;

@interface PEAlbumsModel() {
    MLMediaLibrary* mediaLibrary;
    MLMediaSource *mediaSource;
}
@end

@implementation PEAlbumsModel

- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *options = @{
                                  MLMediaLoadSourceTypesKey: @(MLMediaSourceTypeImage),
                                  MLMediaLoadIncludeSourcesKey: @[MLMediaSourcePhotosIdentifier]
                                  };
        mediaLibrary = [[MLMediaLibrary alloc] initWithOptions:options];
    }
    return self;
}

- (void)beginLoad {
    [mediaLibrary addObserver:self forKeyPath:@"mediaSources" options:0 context:(__bridge void *)mediaLibrary];
    self.tree = [NSMutableArray array];
    // This starts async loading
    [mediaLibrary mediaSources];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == (__bridge void *)mediaLibrary) {
        mediaSource = [mediaLibrary.mediaSources objectForKey:MLMediaSourcePhotosIdentifier];
        
        [mediaSource addObserver:self
                      forKeyPath:@"rootMediaGroup"
                         options:0
                         context:(__bridge void *)mediaSource];
        
        [mediaSource rootMediaGroup];
    }
    else if (context == (__bridge void *)mediaSource)
    {
        MLMediaGroup *albums = [mediaSource mediaGroupForIdentifier:@"TopLevelAlbums"];
        
        [self recurseGroup:albums];

        [[NSNotificationCenter defaultCenter] postNotificationName:PE_NOTIFICATION_ALBUMS_FINISHED object:self];
    }
}

- (void)recurseGroup:(MLMediaGroup*)group {
    [self recurseGroup:group parentNode:nil];
}
- (void)recurseGroup:(MLMediaGroup*)group parentNode:(PEAlbumNode*)parent {
    
    PEAlbumNode* newNode = [[PEAlbumNode alloc] initWithParent:parent group:group];
    if (!parent)
        [self.tree addObject:newNode];
    else
        [parent.children addObject:newNode];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PE_NOTIFICATION_ALBUMS_PROGRESS object:self];
    
    for (MLMediaGroup *subgroup in group.childGroups) {
        [self recurseGroup:subgroup parentNode:newNode];
    }
}


@end
