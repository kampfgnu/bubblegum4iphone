//
//  BubblegumSequencer4iPhoneAppDelegate.h
//  BubblegumSequencer4iPhone
//
//  Created by kampfgnu on 2/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

@class ColorTrackingViewController;

@interface BubblegumSequencer4iPhoneAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ColorTrackingViewController *colorTrackingViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ColorTrackingViewController *viewController;

@end

