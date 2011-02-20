/*

    File: oalPlayback.m
Abstract: An Obj-C class which wraps an OpenAL playback environment
 Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.


*/

#import "SoundManager.h"
#import "MyOpenALSupport.h"
#include <math.h>

@implementation SoundManager

//@synthesize isPlaying = _isPlaying;
@synthesize wasInterrupted = _wasInterrupted;
//@synthesize listenerRotation = _listenerRotation;

void interruptionListener(void* inClientData, UInt32 inInterruptionState)
{
	SoundManager *THIS = (SoundManager*)inClientData;
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{
		// do nothing
		[THIS teardownOpenAL];
//		if ([THIS isPlaying]) {
//			THIS->_wasInterrupted = YES;
//			THIS->_isPlaying = NO;
//		}
	}
	else if (inInterruptionState == kAudioSessionEndInterruption)
	{
		OSStatus result = AudioSessionSetActive(true);
		if (result) printf("Error setting audio session active! %i\n", (int)result);
		[THIS initOpenAL];
		if (THIS->_wasInterrupted)
		{
//			[THIS startSound];
			THIS->_wasInterrupted = NO;
		}
	}
}

- (id) init
{
	if ((self = [super init])) {
		// Start with our sound source slightly in front of the listener
//		_sourcePos = CGPointMake(0., -70.);

		// Put the listener in the center of the stage
//		_listenerPos = CGPointMake(0., 0.);

		// Listener looking straight ahead
//		_listenerRotation = 0.;

		// setup our audio session
		OSStatus result = AudioSessionInitialize(NULL, NULL, interruptionListener, self);
		if (result) printf("Error initializing audio session! %i\n", (int)result);
		else {
			UInt32 category = kAudioSessionCategory_AmbientSound;
			result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
			if (result) printf("Error setting audio session category! %i\n", (int)result);
			else {
				result = AudioSessionSetActive(true);
				if (result) printf("Error setting audio session active! %i\n", (int)result);
			}
		}

		_wasInterrupted = NO;

		sources.reserve(10);
		datas.reserve(10);
		buffers.reserve(10);

		reference = 0;

		// Initialize our OpenAL environment
		[self initOpenAL];
	}

	return self;
}

- (void) initOpenAL
{
	//ALenum error;
	ALCcontext *newContext = NULL;
	ALCdevice *newDevice = NULL;

	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL)
	{
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created
		newContext = alcCreateContext(newDevice, 0);
		if (newContext != NULL)
		{
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(newContext);
		}
	}
	// clear any errors
	alGetError();
}

- (void) playSine
{
	ALuint buffer;
	ALvoid *data;
	ALuint source;
	ALsizei size;

	double pi = 3.141592654;
	int samples = 32;
	int frequency = 220;
	size = samples * frequency;

	char wave[size];

	for (int i = 0; i < size; i++) {
		//sine
		wave[i] = ceil(100*sin(i*(2*pi)/50)+128);
		//saw
//		wave[i] = ceil(1-2*(1-frequency*i / 100));
		//pulse
//		wave[i] = ceil(((i / 100) % 2)*frequency+200);
		//white noise
//		wave[i] = ceil(1 - (int)RandomFloat(0.0f, 12000.0f)+8000);
	}

	data = wave;

	alGenBuffers(1, &buffer);
	alBufferData(buffer, AL_FORMAT_MONO8, data, size, 11024);
	alGenSources(1, &source);
	alSourcef(source, AL_PITCH, 1.0);
	alSourcef(source, AL_GAIN, 1.0);
	alSourcei(source, AL_LOOPING, AL_TRUE);
	alSourcei(source, AL_BUFFER, buffer);
	alSourcePlay(source);

	sources.push_back(source);
	datas.push_back(data);
	buffers.push_back(buffer);

}

- (ALuint) loadCafFile: (NSString*) filename
{
	ALuint buffer;
	void* data;
	ALuint source;

	ALenum  error = AL_NO_ERROR;

	alGenBuffers(1, &buffer);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("Error Generating Buffers: %x", error);
		exit(1);
	}

	// Create some OpenAL Source Objects
	alGenSources(1, &source);
	if(alGetError() != AL_NO_ERROR)
	{
		printf("Error generating sources! %x\n", error);
		exit(1);
	}


	ALenum  format;
	ALsizei size;
	ALsizei freq;

	NSBundle* bundle = [NSBundle mainBundle];

	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource: filename ofType:@"caf"]] retain];

	if (fileURL)
	{
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		CFRelease(fileURL);

		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error loading sound: %x\n", error);
			exit(1);
		}

		// use the static buffer data API
		alBufferDataStaticProc(buffer, format, data, size, freq);

		if((error = alGetError()) != AL_NO_ERROR) {
			printf("error attaching audio to buffer: %x\n", error);
		}
	}
	else
	{
		printf("Could not find file!\n");
		data = NULL;
	}

	error = AL_NO_ERROR;
	alGetError(); // Clear the error
//
	// Set Source Position
//	float sourcePosAL[] = {_sourcePos.x, _sourcePos.y, kDefaultDistance};
//	alSourcefv(source, AL_POSITION, sourcePosAL);

	// Set Source Reference Distance
	alSourcef(source, AL_REFERENCE_DISTANCE, 30.0f);

//	alSourcef(source, AL_PITCH, 2.0f);

//	 attach OpenAL Buffer to OpenAL Source
	alSourcei(source, AL_BUFFER, buffer);
//
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("Error attaching buffer to source: %x\n", error);
		exit(1);
	}

	//ALint bla;
//	alGetSourcei(source, AL_BUFFERS_QUEUED, &bla);
//	Logger::getInstance()->append((int)bla);
//	Logger::getInstance()->saveToFile();
	//vectors to save data...
	sources.push_back(source);
	datas.push_back(data);
	buffers.push_back(buffer);

	return source;
}

- (void) setReference: (NSString*) filename
{
	reference = [self loadCafFile: filename];
	[self setLoop: true source: reference];
	[self setGain: 0.0f source: reference];
	[self startSound: reference];
}

- (int) getReferencePos
{
    ALint pos;
    // Pause the source to prevent the offset from incrementing between
    // getting it and stopping the source (alSourceStop rewinds the source
    // back to 0)
//    alSourcePause(source);
    if (reference != 0) alGetSourcei(reference, AL_SAMPLE_OFFSET,  &pos);
    else pos = 0;

//	Logger::getInstance()->append((int)pos);
//	Logger::getInstance()->saveToFile();

    return pos;
}

- (void) startSound: (ALuint) source
{
	ALenum error;

	//printf("Start!\n");
	// Begin playing our source file
	alSourcePlay(source);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error starting source: %x\n", error);
	} else {
		// Mark our state as playing (the view looks at this)
//		self.isPlaying = YES;
	}
}

- (void) startSoundAtPos: (ALint) pos source: (ALuint) source
{
    alSourcei(source, AL_SAMPLE_OFFSET, pos);
    alSourcePlay(source);
}

- (void) stopSound: (ALuint) source
{
	ALenum error;

	//printf("Stop!!\n");
	// Stop playing our source file
	alSourceStop(source);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error stopping source: %x\n", error);
	} else {
		// Mark our state as not playing (the view looks at this)
//		self.isPlaying = NO;
	}
}

- (void) setLoop: (bool) on source: (ALuint) source
{
	if (on) alSourcei(source, AL_LOOPING, AL_TRUE);
	else alSourcei(source, AL_LOOPING, AL_FALSE);
}

- (void) setPitch:(float)pitch source: (ALuint) source
{
	alSourcef(source, AL_PITCH, pitch);
}

- (void) setGain:(float)gain source: (ALuint) source
{
	alSourcef(source, AL_GAIN, gain);
}

- (int) getPos:(ALint) source
{
    ALint pos;
    // Pause the source to prevent the offset from incrementing between
    // getting it and stopping the source (alSourceStop rewinds the source
    // back to 0)
//    alSourcePause(source);
    alGetSourcei((ALuint)source, AL_SAMPLE_OFFSET,  &pos);
    return (int)pos;
}

- (void) setPos: (ALint) pos source: (ALuint) source
{
    alSourcei(source, AL_SAMPLE_OFFSET, pos);
}

- (float) getGain:(ALuint) source
{
    ALfloat gain;
    // Pause the source to prevent the offset from incrementing between
    // getting it and stopping the source (alSourceStop rewinds the source
    // back to 0)
//    alSourcePause(source);
    alGetSourcef(source, AL_GAIN,  &gain);
    return gain;
}

- (void) rewind: (ALuint) source
{
	alSourceRewind(source);
}

- (bool) isPlaying: (ALuint) source
{
    ALenum state;
    alGetSourcei(source, AL_SOURCE_STATE, &state);
    return (state == AL_PLAYING);
}

- (void) setSourcePos:(CGPoint)SOURCEPOS source: (ALuint) source
{
	float sourcePosAL[] = {SOURCEPOS.x, SOURCEPOS.y, kDefaultDistance};
	// Move our audio source coordinates
	alSourcefv(source, AL_POSITION, sourcePosAL);
}

- (void) setListenerPos:(CGPoint)LISTENERPOS
{
	float listenerPosAL[] = {LISTENERPOS.x, LISTENERPOS.y, 0.};
	// Move our listener coordinates
	alListenerfv(AL_POSITION, listenerPosAL);
}

- (void) setListenerRotation:(CGFloat)radians
{
	float ori[] = {cos(radians + M_PI_2), sin(radians + M_PI_2), 0., 0., 0., 1.};
	// Set our listener orientation (rotation)
	alListenerfv(AL_ORIENTATION, ori);
}

- (void) dealloc
{
	for (int i = 0; i < (int)datas.size(); i++) {
		if (datas.at(i)) free(datas.at(i));
	}
	[self teardownOpenAL];
	[super dealloc];
}

- (void) teardownOpenAL
{
    ALCcontext *context = NULL;
    ALCdevice *device = NULL;

    for (int i = 0; i < (int)sources.size(); i++) {
    	alDeleteSources(1, &sources.at(i));
	}
    for (int j = 0; j < (int)buffers.size(); j++) {
		alDeleteBuffers(1, &buffers.at(j));
	}
	//Get active context (there can only be one)
    context = alcGetCurrentContext();
    //Get device for active context
    device = alcGetContextsDevice(context);
    //Release context
    alcDestroyContext(context);
    //Close device
    alcCloseDevice(device);
}

@end
