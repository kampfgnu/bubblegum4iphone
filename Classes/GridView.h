//
//  GridView.h
//  ColorTracking
//
//  Created by kampfgnu on 2/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GridView : UIView {
	NSMutableArray *grid;
	
	int numRows;
	int numCols;
}

@property (nonatomic, retain) NSMutableArray *grid;

@property (readwrite) int numRows;
@property (readwrite) int numCols;

@end
