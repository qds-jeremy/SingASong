//
//  Initialize.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "Initialize.h"

@implementation Initialize

- (BOOL)checkIsUsingHeadset {
    BOOL isUsingHeadset = NO;
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones] || [[desc portType] isEqualToString:@"Headphones"])
            isUsingHeadset = YES;
    }
    
    /*
     UInt32 routeSize = sizeof (CFStringRef); CFStringRef route;
     AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);
     
     //NSLog(@"Error >>>>>>>>>> :%@", error);
     //     Known values of route:
     //     "Headset"
     //     "Headphone"
     //     "Speaker"
     //     "SpeakerAndMicrophone"
     //     "HeadphonesAndMicrophone"
     //     "HeadsetInOut"
     //     "ReceiverAndMicrophone"
     //     "Lineout"
     
     NSString *routeStr = (__bridge NSString *)route;
     
     NSRange headsetRange = [routeStr rangeOfString : @"Headset"]; NSRange receiverRange = [routeStr rangeOfString : @"Receiver"];
     
     if(headsetRange.location != NSNotFound) {
     // Don't change the route if the headset is plugged in.
     NSLog(@"headphone is plugged in ");
     _isUsingHeadset = YES;
     
     } else {
     if (receiverRange.location != NSNotFound) {
     // Change to play on the speaker
     NSLog(@"play on the speaker");
     } else {
     NSLog(@"Unknown audio route.");
     }
     }
     
     */
    
    return isUsingHeadset;
}

- (AVAudioPlayer *)audioPlayerWithSongURL:(NSURL *)songURL songStartTime:(CMTime )songStartTime {
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:songURL error:nil];
    
    audioPlayer.currentTime = CMTimeGetSeconds(songStartTime);
    
    [audioPlayer prepareToPlay];
    
    //  Allows phone speakers to play during recording
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error: nil];
    
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    return audioPlayer;
}

- (AVCaptureSession *)cameraSession {
    AVCaptureSession * session = [[AVCaptureSession alloc] init];
    
    NSError *error = nil;

    //Add Audio Input
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    [session addInput:audioInput];
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    if (error)
        NSLog(@"add audio input error: %@ %@", error, [error userInfo]);
    
    return session;
}

- (AVCaptureMovieFileOutput *)cameraOutputSettingsForSession:(AVCaptureSession *)session {
    //Add Movie File Output
    AVCaptureMovieFileOutput *output = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 totalSeconds = 60;                                                      //<<Total seconds
    int32_t preferredTimeScale = 30;                                                //<<Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(totalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    output.maxRecordedDuration = maxDuration;
    output.minFreeDiskSpaceLimit = 1024 * 1024;                                     //<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    return output;
}

- (AVCaptureDeviceInput *)getNewViewInputForDeviceInput:(AVCaptureDeviceInput *)deviceInput {
    
    NSError *error;
    
    AVCaptureDeviceInput *newVideoInput;

    AVCaptureDevicePosition position = [[deviceInput device] position];

    if (position == AVCaptureDevicePositionBack) {
        
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        
    } else if (position == AVCaptureDevicePositionFront) {
    
        newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:&error];
    
    }
    return newVideoInput;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position)
            return device;
    }
    return nil;
}

@end
