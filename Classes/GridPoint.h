//
//  GridPoint.h
//  ColorTracking
//
//  Created by kampfgnu on 2/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@interface GridPoint : NSObject {
	int x;
	int y;
	UIView *view;
}

@property (readwrite) int x;
@property (readwrite) int y;
@property (nonatomic, retain) UIView *view;

- (void)setViewColor:(Color)color;

@end
