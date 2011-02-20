//
//  GridView.m
//  ColorTracking
//
//  Created by kampfgnu on 2/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GridView.h"

#import "GridPoint.h"

@implementation GridView

@synthesize grid;
@synthesize numCols, numRows;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		grid = [[NSMutableArray alloc] init];
		
		numRows = GRID_NUM_ROWS;
		numCols = GRID_NUM_COLS;
		
		int offsetX = 30;
		int offsetY = 30;
		
		int minX = offsetX;
		int maxX = frame.size.width-offsetX;
		int minY = offsetY;
		int maxY = frame.size.height-offsetY;
		
		int width = (maxX-minX);
		int height = (maxY-minY);
		
		for (int i = 0; i < numRows; i++) {
			NSMutableArray *row = [[NSMutableArray alloc] init];
			for (int j = 0; j < numCols; j++) {
				GridPoint *p = [[GridPoint alloc] init];
				p.x = minX + i * (width/numRows);
				p.y = minY + j * (height/numCols);
				
				[row addObject:p];
				[p release];
				
				int viewA = 13;
				UIView *view = [[UIView alloc] initWithFrame:CGRectMake(p.x - viewA/2, p.y - viewA/2, viewA, viewA)];
				view.backgroundColor = [UIColor whiteColor];
				[self addSubview:view];
				[view release];
				p.view = [view autorelease];
			}
			[grid addObject:row];
			[row release];
		}
		
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	[grid release];
	
    [super dealloc];
}


@end
