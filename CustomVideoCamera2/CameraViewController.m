//
//  CameraViewController.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "CameraViewController.h"
#import "PlayVideoViewController.h"

@implementation CameraViewController

@synthesize previewLayer, initialize;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _exportCapture = [ExportCapture new];
//    _exportCapture.delegate = self;
    
    [self initializeCameraAndAudioPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientaionDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientaionDidChange:(UIInterfaceOrientation)interfaceOrientation {
    
    if (isRecording)
        return;
    [self cameraSetOutputProperties];
    [self sizeCameraForOrientation];
}

- (void)startCountdown {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimerLabel) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)initializeCameraAndAudioPlayer {
    initialize = [Initialize new];
    _audioPlayer = [initialize audioPlayerWithSongURL:_songURL songStartTime:_songStartTime];
    _audioPlayer.delegate = self;
    [self setupCaptureSession];
}

- (void)updateTimerLabel {
    int countdownNumber = _labelCountdown.text.intValue;
    countdownNumber--;
    
    if (countdownNumber > 0) {
    _labelCountdown.text = [NSString stringWithFormat:@"%i", countdownNumber];
    } else {
        [_labelCountdown setHidden:YES];
        [_timer invalidate];
        _isUsingHeadset = [initialize checkIsUsingHeadset];
        [self startSongAndRecording];
    }
}

- (void)startSongAndRecording {
    [_audioPlayer play];
    [self startRecording];
}

- (void)setupCaptureSession {
    isRecording = NO;
    session = [initialize cameraSession];

    //Add Video Input
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!error) {
        if ([session canAddInput:deviceInput])
            [session addInput:deviceInput];
        else
            NSLog(@"Couldn't add video input");
    } else
        NSLog(@"Couldn't create video input");
    
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:session]];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    _filmedOrientationOfScreen = UIInterfaceOrientationPortrait;
    [[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    output = [initialize cameraOutputSettingsForSession:session];
    if ([session canAddOutput:output])
        [session addOutput:output];
    
    UIView *cameraView = [UIView new];
    [_viewForPreview addSubview:cameraView];
    [cameraView.layer addSublayer:previewLayer];
    
    [self sizeCameraForOrientation];
    [self cameraSetOutputProperties];
    
    [session startRunning];
}

- (void)sizeCameraForOrientation {
    _viewForPreview.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    CGRect layerRect = _viewForPreview.layer.bounds;
    [previewLayer setBounds:layerRect];
    [previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect))];
}

- (void)cameraSetOutputProperties {
    if (isRecording)
        return;
    
    _screenWidth = UIScreen.mainScreen.bounds.size.width;
    _screenHeight = UIScreen.mainScreen.bounds.size.height;
    
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        _filmedOrientationOfScreen = UIInterfaceOrientationPortrait;
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        _filmedOrientationOfScreen = UIInterfaceOrientationLandscapeLeft;
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        _filmedOrientationOfScreen = UIInterfaceOrientationLandscapeRight;
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
}



- (void)startRecording {
    _filmedOrientationOfScreen = UIDevice.currentDevice.orientation;
    
    //Create temporary URL to record to
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            NSLog(@"record error: %@ %@", error, [error userInfo]);
    }
    [output startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

- (void)stopRecording {
    isRecording = NO;
    [output stopRecording];
    [_audioPlayer pause];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    _isExporting = YES;
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully) {
        AVAsset *assetCaptured = [AVAsset assetWithURL:outputFileURL];
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        
        // 2 - Create video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        // 3 - Audio track
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
        audioTrack.preferredVolume = 10;
        
        if (_isUsingHeadset) {
            // 4 - Music track
            if (_songURL != nil) {
                
                AVAsset *assetSong = [AVAsset assetWithURL:_songURL];
                
                AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:2];
                [musicTrack insertTimeRange:CMTimeRangeMake(_songStartTime, assetCaptured.duration) ofTrack:[[assetSong tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                musicTrack.preferredVolume = 0.01;
                
            }
        }
        
        //  This code does work, but perhaps best practice is to rotate the video via an instruction layer?
                if (_filmedOrientationOfScreen == 4) {
                    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2 * 2);
                    videoTrack.preferredTransform = rotationTransform;
                } else if (_filmedOrientationOfScreen == 1) {
                    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
                    videoTrack.preferredTransform = rotationTransform;
                }
        
        
//        // 3.1 - Create AVMutableVideoCompositionInstruction
        AVMutableVideoComposition *videoComp = [AVMutableVideoComposition videoComposition];
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, assetCaptured.duration);
        
        //  5 Add animation overlays
        BOOL addAnimationInstructionLayer = NO;
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        [parentLayer addSublayer:videoLayer];
        //        CGSize videoSize = [[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
        CGSize videoSize = [videoTrack naturalSize];
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        
        if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Overlay Added"]) {
         
            addAnimationInstructionLayer = YES;
            UIImage *insideBorderImage = [UIImage imageNamed:@"In_Video_Border.png"];
            CALayer *aLayer = [CALayer layer];
            aLayer.contents = (id)insideBorderImage.CGImage;
            aLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
            [parentLayer addSublayer:aLayer];
            
        }
        
        if ([_buttonAddText.titleLabel.text isEqualToString:@"Text Added"]) {
            
            addAnimationInstructionLayer = YES;
            CATextLayer *text = [CATextLayer layer];
            text.string = @"Put In Text Here";
            text.frame = CGRectMake(100, 200, 320, 50);
            CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
            text.font = font;
            text.fontSize = 40;
            text.foregroundColor = [UIColor whiteColor].CGColor;
            [text display];
            [parentLayer addSublayer:text];
            
        }
        
        if (addAnimationInstructionLayer) {
                mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
                AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
                
                BOOL isPortrait = NO;
                if (_filmedOrientationOfScreen == 4) {
                    //                CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2 * 2);
                    //                [layerInstruction setTransform:transform atTime:kCMTimeZero];
                } else if (_filmedOrientationOfScreen == 1) {
                    //                CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
                    //                [layerInstruction setTransform:transform atTime:kCMTimeZero];
                    isPortrait = YES;
                }
                
                CGSize naturalSize;
                if(isPortrait){
                    naturalSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
                } else {
                    naturalSize = videoTrack.naturalSize;
                }
                
                videoComp.renderSize = videoSize;
                videoComp.frameDuration = CMTimeMake(1, 30);
                videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
                mainInstruction.layerInstructions = @[ layerInstruction ];
                videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
        }
        
        // 6 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        NSURL *exportURL = [NSURL fileURLWithPath:myPathDocs];
        
        // 7 - Create exporter
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = exportURL;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        
        if (addAnimationInstructionLayer)
            exporter.videoComposition = videoComp;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
//                [_exportCapture exportDidFinish:exporter];
                [self exportDidFinish:exporter exportPathURL:exportURL];
            });
        }];
    }
}

- (void)exportDidFinish:(AVAssetExportSession *)exportSession exportPathURL:(NSURL *)exportURL {
    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = exportSession.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        
                        PlayVideoViewController *vc = [PlayVideoViewController new];
                        vc.url = exportURL;
                        [self presentViewController:vc animated:YES completion:nil];
                        
                    }
                });
            }];
        }
        
        _isExporting = NO;
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"did not get true for AVAssetExportSessionStatusCompleted" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
}

#pragma mark ExportCapture Delegate
- (void)exportComplete {
    _isExporting = NO;
}

- (IBAction)cameraToggleButtonPressed:(id)sender {
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1) {  //  Only do if device has multiple cameras
        AVCaptureDeviceInput *newVideoInput = [initialize getNewViewInputForDeviceInput:deviceInput];
        if (newVideoInput != nil) {
            [session beginConfiguration];   //  We can now change the inputs and output configuration.  Use commitConfiguration to end
            [session removeInput:deviceInput];
            if ([session canAddInput:newVideoInput]) {
                [session addInput:newVideoInput];
                deviceInput = newVideoInput;
            } else {
                [session addInput:deviceInput];
            }
            [self cameraSetOutputProperties];
            [session commitConfiguration];
        }
    }
}

- (IBAction)startStopButtonPressed:(id)sender {
    if (_isExporting)
        return;
    
    if (isRecording) {
        [_buttonStartStop setTitle:@"Start" forState:UIControlStateNormal];
        [self stopRecording];
    } else {
        isRecording = YES;
        [_buttonStartStop setTitle:@"Stop" forState:UIControlStateNormal];
        [self startCountdown];
    }
}

- (IBAction)overlayPressed:(id)sender {
    if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Add Overlay"])
        [_buttonAddOverlay setTitle:@"Overlay Added" forState:UIControlStateNormal];
    else
        [_buttonAddOverlay setTitle:@"Add Overlay" forState:UIControlStateNormal];
}

- (IBAction)textPressed:(id)sender {
    if ([_buttonAddText.titleLabel.text isEqualToString:@"Text"])
        [_buttonAddText setTitle:@"Text Added" forState:UIControlStateNormal];
    else
        [_buttonAddText setTitle:@"Text" forState:UIControlStateNormal];
}

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end