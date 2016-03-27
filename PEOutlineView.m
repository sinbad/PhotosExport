//
//  PEOutlineView.m
//  PhotosExport
//
//  Created by Steven Streeting on 27/03/2016.
//  Copyright © 2016 Steven Streeting. All rights reserved.
//

#import "PEOutlineView.h"

@interface NSObject(PEOutlineViewDelegate)
-(BOOL)outlineView:(NSOutlineView*)t keyDown:(NSEvent*)theEvent;
@end

@implementation PEOutlineView

-(void) keyDown:(NSEvent *)theEvent
{
	// Allow simpler keyboard handling in delegate
	id d = [self delegate];
	if (d && [d respondsToSelector:@selector(outlineView:keyDown:)])
	{
		if([d outlineView:self keyDown:theEvent])
			return;
	}
	
	// Propagate otherwise
	[super keyDown:theEvent];
}
@end
