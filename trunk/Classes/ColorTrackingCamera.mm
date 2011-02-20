//
//  ColorTrackingCamera.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/9/2010.
//

#import "ColorTrackingCamera.h"

@implementation ColorTrackingCamera

#pragma mark -
#pragma mark Initialization and teardown

- (id)init; 
{
	if (!(self = [super init]))
		return nil;
	
	
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
	
	// Grab the back-facing camera
	AVCaptureDevice *camera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		BOOL useFrontCam = [[NSUserDefaults standardUserDefaults] boolForKey:@"cam_key"];
		if ([device position] == (useFrontCam ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)) 
		{
			camera = device;
		}
//		if (!useFrontCam) {
//			if ([device hasTorch] && [device hasFlash]) {
//
//				[captureSession beginConfiguration];
//				[device lockForConfiguration:nil];
//				[device setTorchMode:AVCaptureTorchModeOn];
//				[device setFlashMode:AVCaptureFlashModeOn];
//				[device unlockForConfiguration];
//				[captureSession commitConfiguration];
//				[captureSession startRunning];
//			}
//		}
	}
	
	// Add the video input	
	NSError *error = nil;
	videoInput = [[[AVCaptureDeviceInput alloc] initWithDevice:camera error:&error] autorelease];
	if ([captureSession canAddInput:videoInput]) 
	{
		[captureSession addInput:videoInput];
	}
	
	[self videoPreviewLayer];
	// Add the video frame output	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
	// Use RGB frames instead of YUV to ease color processing
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	videoOutput.minFrameDuration = CMTimeMake(1, 6);
	
//	dispatch_queue_t videoQueue = dispatch_queue_create("com.sunsetlakesoftware.colortracking.videoqueue", NULL);
//	[videoOutput setSampleBufferDelegate:self queue:videoQueue];

//	dispatch_queue_t videoQueue = dispatch_queue_create("com.sunsetlakesoftware.colortracking.videoqueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

	if ([captureSession canAddOutput:videoOutput])
	{
		[captureSession addOutput:videoOutput];
	}
	else
	{
		NSLog(@"Couldn't add video output");
	}

	// Start capturing
//	[captureSession setSessionPreset:AVCaptureSessionPresetHigh];
	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
	if (![captureSession isRunning])
	{
		[captureSession startRunning];
	};
	
	return self;
}

- (void)dealloc 
{
	[captureSession stopRunning];

	[captureSession release];
	[videoPreviewLayer release];
	[videoOutput release];
	[videoInput release];
	[super dealloc];
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	if (currentBuffer) CFRelease(currentBuffer);
	currentBuffer = nil;
	CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &currentBuffer);
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	[self.delegate displayNewCameraFrame:pixelBuffer];
}

- (CMSampleBufferRef)sampleBuffer {
	return currentBuffer;
}

#pragma mark -
#pragma mark Accessors

@synthesize delegate;
@synthesize videoPreviewLayer;

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer;
{
	if (videoPreviewLayer == nil)
	{
		videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        
        if ([videoPreviewLayer isOrientationSupported]) 
		{
            [videoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	}
	
	return videoPreviewLayer;
}

@end
