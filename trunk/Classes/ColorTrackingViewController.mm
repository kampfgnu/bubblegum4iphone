//
//  ColorTrackingViewController.m
//  ColorTracking
//
//
//  The source code for this application is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 10/7/2010.
//

#import "ColorTrackingViewController.h"

#import "GridView.h"
#import "GridPoint.h"
#import "SoundManager.h"

// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
	UNIFORM_INPUTCOLOR,
	UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@implementation ColorTrackingViewController

#define DEBUG

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithScreen:(UIScreen *)newScreenForDisplay;
{
    if ((self = [super initWithNibName:nil bundle:nil])) 
	{
		screenForDisplay = newScreenForDisplay;
		
		rawPositionPixels = (GLubyte *) calloc(FBO_WIDTH * FBO_HEIGHT * 4, sizeof(GLubyte));
		
		sndMgr = [[SoundManager alloc] init];
		sounds = [[NSMutableArray alloc] init];
//		[sounds setObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"hihatclosed"]] forKey:@"hihatclosed"];
//		[sounds setObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"kick"]] forKey:@"kick"];
//		[sounds setObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"ride"]] forKey:@"ride"];
//		[sounds setObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"snare"]] forKey:@"snare"];
		[sounds addObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"hihatclosed"]]];
		[sounds addObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"kick"]]];
		[sounds addObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"ride"]]];
		[sounds addObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"snare"]]];
		[sounds addObject:[NSNumber numberWithInt:[sndMgr loadCafFile:@"tom"]]];
		
		step = 0;
	}
    return self;
}

- (void)loadView 
{
	CGRect applicationFrame = [screenForDisplay applicationFrame];	
	CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	UIView *primaryView = [[UIView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;
	[primaryView release];

	glView = [[ColorTrackingGLView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, applicationFrame.size.width, applicationFrame.size.height)];	
	[self.view addSubview:glView];
	[glView release];
	
	[self loadVertexShader:@"DirectDisplayShader" fragmentShader:@"DirectDisplayShader" forProgram:&directDisplayProgram];
		
	colorView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-20, self.view.bounds.size.height-20, 20, 20)];
	[self.view addSubview:colorView];
	[colorView release];
	
	CGPoint pos = CGPointMake(self.view.bounds.size.width-30, self.view.bounds.size.height-30);
	int offset = 1;
	colorCheckPosView = [[UIView alloc] initWithFrame:CGRectMake(pos.x-offset, pos.y-offset, 3, 3)];
	colorCheckPosView.backgroundColor = [UIColor blueColor];
	[self.view addSubview:colorCheckPosView];
	[colorCheckPosView release];
	
	gridView = [[GridView alloc] initWithFrame:self.view.frame];
	[self.view addSubview:gridView];
	[gridView release];
	
	camera = [[ColorTrackingCamera alloc] init];
	camera.delegate = self;
	[self cameraHasConnected];
	
	nextBeat = [[NSDate alloc] initWithTimeIntervalSinceNow:60.0/BPM];

	NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(timerMethod:) object:nil];
	[t setThreadPriority:1.0];
	//[NSThread detachNewThreadSelector:@selector(timerMethod:) toTarget:self withObject:nil];
	[t start];
	//[NSTimer scheduledTimerWithTimeInterval:60.0/BPM target:self selector:@selector(timerMethod:) userInfo:nil repeats:YES];
}

- (void)didReceiveMemoryWarning 
{
//    [super didReceiveMemoryWarning];
}

- (void)dealloc 
{
	free(rawPositionPixels);
	[camera release];
    [super dealloc];
}

#pragma mark -
#pragma mark OpenGL ES 2.0 rendering methods

- (void)drawFrame
{    
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

	static const GLfloat textureVertices[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        0.0f,  0.0f,
    };

/*	static const GLfloat passthroughTextureVertices[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };
*/	
//    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT);
    
	// Use shader program.
	[glView setDisplayFramebuffer];
	glUseProgram(directDisplayProgram);

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
	
	// Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	//draw grid
//	CGPoint p1 = CGPointMake(0, 0);
//	CGPoint p2 = CGPointMake(30, self.view.frame.size.height-30);
//	GLfloat glVertices[] = {p1.x,p1.y,p2.x,p2.y};
//	glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, glVertices);
//	glEnableVertexAttribArray(0);
//	glDrawArrays(GL_LINES, 0, 2);
    
    [glView presentFramebuffer];
}

#pragma mark -
#pragma mark OpenGL ES 2.0 setup methods

- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
{
    GLuint vertexShader, fragShader;
	
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer])
    {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer)
        {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    // Release vertex and fragment shaders.
    if (vertexShader)
	{
        glDeleteShader(vertexShader);
	}
    if (fragShader)
	{
        glDeleteShader(fragShader);		
	}
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

#pragma mark -
#pragma mark Image processing

- (CGPoint)centroidFromTexture:(GLubyte *)pixels;
{
	CGFloat currentXTotal = 0.0f, currentYTotal = 0.0f, currentPixelTotal = 0.0f;
	
	for (NSUInteger currentPixel = 0; currentPixel < (FBO_WIDTH * FBO_HEIGHT); currentPixel++)
	{
		currentYTotal += (CGFloat)pixels[currentPixel * 4] / 255.0f;
		currentXTotal += (CGFloat)pixels[(currentPixel * 4) + 1] / 255.0f;
		currentPixelTotal += (CGFloat)pixels[(currentPixel * 4) + 3] / 255.0f;
	}
	
	return CGPointMake(1.0f - (currentXTotal / currentPixelTotal), currentYTotal / currentPixelTotal);
}

#pragma mark -
#pragma mark ColorTrackingCameraDelegate methods

- (void)cameraHasConnected;
{
//	NSLog(@"Connected to camera");
/*	camera.videoPreviewLayer.frame = self.view.bounds;
	[self.view.layer addSublayer:camera.videoPreviewLayer];*/
}

- (void)displayNewCameraFrame:(CVImageBufferRef)cameraFrame;
{
	CVPixelBufferLockBaseAddress(cameraFrame, 0);
	int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
	int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
	
//	CGPoint pos = CGPointMake(colorCheckPosView.frame.origin.x+1, colorCheckPosView.frame.origin.y+1);
//	int scaledVideoPointX = round((self.view.bounds.size.width - pos.x) * (CGFloat)bufferHeight / self.view.bounds.size.width);
//	int scaledVideoPointY = round(pos.y * (CGFloat)bufferWidth / self.view.bounds.size.height);
//	
//	unsigned char *pixel = rowBase + (scaledVideoPointX * bytesPerRow) + (scaledVideoPointY * 4);
//	
//	float r = (float)pixel[2] / 255.0;
//	float g = (float)pixel[1] / 255.0;
//	float b = (float)pixel[0] / 255.0;
//	
//	
//	[self RGBtoHSV:r g:g b:b];
//	
//	colorView.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
	
	//NSLog(@"r: %f, g: %f, b: %f", thresholdColor[0], thresholdColor[1], thresholdColor[2]);

	// Create a new texture from the camera frame data, display that using the shaders
	glGenTextures(1, &videoFrameTexture);
	glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Using BGRA extension to pull in video frame data directly
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));

	[self drawFrame];
	
	glDeleteTextures(1, &videoFrameTexture);

	CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}

- (void)processBuffer:(CVImageBufferRef)cameraFrame {
	CVPixelBufferLockBaseAddress(cameraFrame, 0);
	int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
	int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
	
	unsigned char *rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);
	int bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
	
	for (int i = 0; i < gridView.numRows; i++) {
		NSMutableArray *row = [gridView.grid objectAtIndex:i];
		for (int j = 0; j < gridView.numCols; j++) {
			GridPoint *p = [row objectAtIndex:j];
			
			if (j == step) {
				CGPoint pos = CGPointMake(p.x, p.y);
				int scaledVideoPointX = round((self.view.bounds.size.width - pos.x) * (CGFloat)bufferHeight / self.view.bounds.size.width);
				int scaledVideoPointY = round(pos.y * (CGFloat)bufferWidth / self.view.bounds.size.height);
				
				unsigned char *pixel = rowBase + (scaledVideoPointX * bytesPerRow) + (scaledVideoPointY * 4);
				
				float r = (float)pixel[2] / 255.0;
				float g = (float)pixel[1] / 255.0;
				float b = (float)pixel[0] / 255.0;
				
				float h = [self RGBtoHSV:r g:g b:b];
				Color color = [self hToColor:h];
				[p setViewColor:color];

				[self playColor:color];
			}
			else {
				p.view.backgroundColor = [UIColor whiteColor];
			}
			
		}
	}
	
	step++;
	if (step == GRID_NUM_COLS) step = 0;
	
	CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}

// r,g,b values are from 0 to 1
// h = [0,360], s = [0,1], v = [0,1]
//		if s == 0, then h = -1 (undefined)

- (float)RGBtoHSV:(float)r g:(float)g b:(float)b {
	float h, s, v;
	float min, max, delta;
	
	min = MIN(MIN(r, g), b);
	max = MAX(MAX(r, g), b);
	v = max;				// v
	
	delta = max - min;
	
	if (max != 0) s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		s = 0;
		h = -1;
		return 0;
	}
	
	if (r == max) h = ( g - b ) / delta;		// between yellow & magenta
	else if (g == max) h = 2 + (b - r) / delta;	// between cyan & yellow
	else h = 4 + (r - g) / delta;	// between magenta & cyan
	
	h *= 60;				// degrees
	if( h < 0 )
		h += 360;
			  
	NSLog(@"hhhhh: %f", h);
	return h;
}

- (Color)hToColor:(float)h {
	if (h < 60) return ColorNone;
	else if (h < 120) return ColorYellow;
	else if (h < 180) return ColorGreen;
	else if (h < 240) return ColorBlue;
	else if (h < 300) return ColorPurple;
	else return ColorRed;
}

- (void)timerMethod:(NSThread *)thread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while (YES) {
		[self performSelectorOnMainThread:@selector(doActualProcessing) withObject:nil waitUntilDone:NO];
//		[self doActualProcessing];
		NSDate *newNextBeat=[[NSDate alloc] initWithTimeInterval:60.0/BPM sinceDate:nextBeat];
		[nextBeat release];
		nextBeat = newNextBeat;
//		NSLog(@"nextBeat: %@", nextBeat);
		[NSThread sleepUntilDate:nextBeat];
		//[NSThread sleepForTimeInterval:1.0];
	}
	

	
	[pool release];
}

- (void)doActualProcessing {
	CMSampleBufferRef sRef = [camera sampleBuffer];
	if (sRef) {
		BOOL dataIsReady = CMSampleBufferDataIsReady(sRef);
		if (dataIsReady) [self processBuffer:CMSampleBufferGetImageBuffer(sRef)];
	}
}

- (void)playColor:(Color)color {
	if (color != ColorNone) {
		int src = [[sounds objectAtIndex:color] intValue];
		[sndMgr startSound:src];
	}	
}

#pragma mark -
#pragma mark Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	currentTouchPoint = [[touches anyObject] locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
//	CGPoint movedPoint = [[touches anyObject] locationInView:self.view]; 
//	CGFloat distanceMoved = sqrt( (movedPoint.x - currentTouchPoint.x) * (movedPoint.x - currentTouchPoint.x) + (movedPoint.y - currentTouchPoint.y) * (movedPoint.y - currentTouchPoint.y) );
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
}

#pragma mark -
#pragma mark Accessors

@synthesize glView;

@end
