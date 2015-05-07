//
//  CameraViewController.h
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CommonCrypto/CommonDigest.h>
#import <AssetsLibrary/AssetsLibrary.h>		//<<Can delete if not storing videos to the photo library.  Delete the assetslibrary framework too requires this)

#import "Initialize.h"
#import "ExportCapture.h"

@interface CameraViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, AVAudioPlayerDelegate, ExportCaptureProtocal> {
    BOOL isRecording;
    
    AVCaptureSession *session;
    AVCaptureMovieFileOutput *output;
    AVCaptureDeviceInput *deviceInput;
}

@property (strong, nonatomic) Initialize *initialize;
@property (strong, nonatomic) ExportCapture *exportCapture;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) AVVideoCompositionCoreAnimationTool *composition;

@property (assign, nonatomic) BOOL isUsingHeadset;
@property (assign, nonatomic) BOOL isExporting;
@property (assign, nonatomic) BOOL isVideoAssetPortrait;

@property (assign, nonatomic) float screenWidth;
@property (assign, nonatomic) float screenHeight;
@property (assign, nonatomic) float filmedOrientationOfScreen;

@property (assign, nonatomic) CMTime songStartTime;

@property (strong, nonatomic) NSURL *songURL;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) AVMutableVideoCompositionInstruction *mainInstruction;

@property (strong, nonatomic) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIView *viewForPreview;
@property (weak, nonatomic) IBOutlet UILabel *labelCountdown;
@property (weak, nonatomic) IBOutlet UIButton *buttonStartStop;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddOverlay;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddText;

- (void)cameraSetOutputProperties;

- (IBAction)startStopButtonPressed:(id)sender;
- (IBAction)cameraToggleButtonPressed:(id)sender;

@end