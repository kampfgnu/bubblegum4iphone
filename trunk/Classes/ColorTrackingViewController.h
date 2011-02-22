//
//  ColorTrackingViewController.h
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import <UIKit/UIKit.h>
#import "ColorTrackingCamera.h"
#import "ColorTrackingGLView.h"

@class GridView;
@class SoundManager;

@interface ColorTrackingViewController : UIViewController <ColorTrackingCameraDelegate> {
	ColorTrackingCamera *camera;
	UIScreen *screenForDisplay;
	ColorTrackingGLView *glView;
	
	GLuint directDisplayProgram;
	GLuint videoFrameTexture;
	
	GLubyte *rawPositionPixels;
	
	GridView *gridView;
	UIView *colorView;
	UIView *colorCheckPosView;
	
	CGPoint currentTouchPoint;
	
	int step;
	
	SoundManager *sndMgr;
	NSMutableDictionary *sounds;
//	NSMutableArray *sounds;
	NSDate *nextBeat;
	BOOL runProcessingThread;
}

@property(readonly) ColorTrackingGLView *glView;

// Initialization and teardown
- (id)initWithScreen:(UIScreen *)newScreenForDisplay;

// OpenGL ES 2.0 setup methods
- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// Image processing
- (CGPoint)centroidFromTexture:(GLubyte *)pixels;

- (void)processBuffer:(CVImageBufferRef)cameraFrame;
- (void)RGB2HSV:(float)r g:(float)g b:(float)b h:(float *)h s:(float*)s v:(float*)v;
- (Color)HSV2Color:(float)h s:(float)s v:(float)v;
- (NSString *)color2String:(Color)color;
- (void)timerMethod:(NSThread *)thread;
- (void)doActualProcessing;
- (void)playColor:(Color)color;

@end

