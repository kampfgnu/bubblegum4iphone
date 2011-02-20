//
//  GridPoint.m
//  ColorTracking
//
//  Created by kampfgnu on 2/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GridPoint.h"


@implementation GridPoint

@synthesize x, y, view;

- (void)dealloc {
	[view release];
	
    [super dealloc];
}

- (void)setViewColor:(Color)color {
	UIColor *col;
	switch (color) {
		case ColorYellow:
			col = [UIColor yellowColor];
			break;
		case ColorGreen:
			col = [UIColor greenColor];
			break;
		case ColorBlue:
			col = [UIColor blueColor];
			break;
		case ColorPurple:
			col = [UIColor purpleColor];
			break;
		case ColorRed:
			col = [UIColor redColor];
			break;
		default:
			col = [UIColor blackColor];
			break;
	}
	view.backgroundColor = col;
}

@end
