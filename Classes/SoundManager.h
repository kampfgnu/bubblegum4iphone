/*

    File: oalPlayback.h
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

#import <UIKit/UIKit.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

#import <vector>

#define kDefaultDistance 25.0

@interface SoundManager : NSObject
{
	std::vector<ALuint> sources;
	std::vector<ALuint> buffers;
	std::vector<void*> datas;
//	CGPoint			_sourcePos;
//	CGPoint			_listenerPos;
//	CGFloat			_listenerRotation;
//	ALfloat			_sourceVolume;
//	BOOL			_isPlaying;
	BOOL			_wasInterrupted;
	int reference;
}

//@property			BOOL isPlaying; // Whether the sound is playing or stopped
@property			BOOL wasInterrupted; // Whether playback was interrupted by the system
//@property			CGPoint sourcePos; // The coordinates of the sound source
//@property			CGPoint listenerPos; // The coordinates of the listener
//@property			CGFloat listenerRotation; // The rotation angle of the listener in radians

- (void) initOpenAL;
- (void) teardownOpenAL;

- (void) playSine;

- (ALuint) loadCafFile: (NSString*) filename;
- (void) setReference: (NSString*) filename;
- (int) getReferencePos;
- (void) startSound: (ALuint) source;
- (void) startSoundAtPos: (ALint) pos source: (ALuint) source;
- (void) stopSound: (ALuint) source;
- (void) setLoop: (bool) on source: (ALuint) source;
- (int) getPos:(ALint) source;
- (void) setPos: (ALint) pos source: (ALuint) source;
- (void) setGain:(float)gain source: (ALuint) source;
- (float) getGain:(ALuint) source;
- (void) setPitch:(float)pitch source: (ALuint) source;
- (void) rewind: (ALuint) source;
- (bool) isPlaying: (ALuint) source;

- (void) setListenerPos:(CGPoint)LISTENERPOS;
- (void) setListenerRotation:(CGFloat)radians;
- (void) setSourcePos:(CGPoint)SOURCEPOS source: (ALuint) source;

@end
