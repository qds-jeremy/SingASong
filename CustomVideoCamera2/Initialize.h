//
//  Initialize.h
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Initialize : NSObject

- (BOOL)checkIsUsingHeadset;

- (NSString *)getFileNameForVideo;

- (AVAudioPlayer *)audioPlayerWithSongURL:(NSURL *)songURL songStartTime:(CMTime )songStartTime;

- (AVCaptureSession *)cameraSession;

- (AVCaptureMovieFileOutput *)cameraOutputSettingsForSession:(AVCaptureSession *)session;

- (AVCaptureDeviceInput *)getNewViewInputForDeviceInput:(AVCaptureDeviceInput *)deviceInput;

@end
