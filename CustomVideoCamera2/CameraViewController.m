#import "CameraViewController.h"

@implementation CameraViewController

@synthesize previewLayer, initialize;

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    } else {
        NSLog(@"Couldn't create video input");
    }
    
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:session]];
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
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
    AVCaptureConnection *captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
}

//********** CAMERA TOGGLE **********
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




//********** START STOP RECORDING BUTTON **********
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

- (void)startRecording {
    
    //----- START RECORDING -----
    NSLog(@"START RECORDING");
    
    //Create temporary URL to record to
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            //Error - handle if requried
        }
    }
    //Start recording
    [output startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    
}

- (void)stopRecording {
    //----- STOP RECORDING -----
    NSLog(@"STOP RECORDING");
    isRecording = NO;
    
    [output stopRecording];
    
    [_audioPlayer pause];
}


//********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    
    _isExporting = YES;
    
    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
    
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
    if (RecordedSuccessfully)
    {
        
        
//        //----- RECORDED SUCESSFULLY -----
//        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
//        {
//            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
//                                        completionBlock:^(NSURL *assetURL, NSError *error)
//             {
//                 if (error)
//                 {
//                     
//                 }
//             }];
//        }
        
        
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
        
        AVMutableVideoComposition *videoComp;
        if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Overlay Added"]) {
            
            CGSize videoSize = [assetCaptured naturalSize];
            
            UIImage *myImage = [UIImage imageNamed:@"In_Video_Border.png"];
            CALayer *aLayer = [CALayer layer];
            aLayer.contents = (id)myImage.CGImage;
            aLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//            aLayer.opacity = 0.65;
            CALayer *parentLayer = [CALayer layer];
            CALayer *videoLayer = [CALayer layer];
            parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
            videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
            [parentLayer addSublayer:videoLayer];
            [parentLayer addSublayer:aLayer];

            
            CATextLayer *text = [CATextLayer layer];
            text.string = @"Put In Text Here";
            text.frame = CGRectMake(100, 200, 320, 50);
            CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
            text.font = font;
            text.fontSize = 40;
            text.foregroundColor = [UIColor whiteColor].CGColor;
            [text display];
            [parentLayer addSublayer:text];
            
            
            AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
            AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            videoComp = [AVMutableVideoComposition videoComposition];
            videoComp.renderSize = videoSize;
            videoComp.frameDuration = CMTimeMake(1, 30);
            videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
            mainInstruction.layerInstructions = @[ layerInstruction ];
            videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
            
        }
        
        if (_isUsingHeadset) {
            // 4 - Music track
            if (_songURL != nil) {
                
                AVAsset *assetSong = [AVAsset assetWithURL:_songURL];
                
                AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:2];
                [musicTrack insertTimeRange:CMTimeRangeMake(_songStartTime, assetCaptured.duration) ofTrack:[[assetSong tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
                musicTrack.preferredVolume = 0.01;
                
            }
        }
        
        // 5 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        
        // 6 - Create exporter
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        
        if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Overlay Added"])
            exporter.videoComposition = videoComp;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self exportDidFinish:exporter];
            });
        }];
        
        
    }
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size {
    // 1 - set up the overlay
    CALayer *overlayLayer = [CALayer layer];
    UIImage *overlayImage = nil;
    overlayImage = [UIImage imageNamed:@"In_Video_Border.png"];
    
    [overlayLayer setContents:(id)[overlayImage CGImage]];
    overlayLayer.frame = CGRectMake(0, 0, 640, 480);
    [overlayLayer setMasksToBounds:YES];
    
    // 2 - set up the parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, _viewForPreview.frame.size.width, _viewForPreview.frame.size.height);
    videoLayer.frame = CGRectMake(0, 0, _viewForPreview.frame.size.width, _viewForPreview.frame.size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    // 3 - apply magic
    _composition = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)exportDidFinish:(AVAssetExportSession *)exportSession {
    
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
                    }
                });
    }];
        }
    }
    
    _isExporting = NO;
    
}

- (IBAction)overlayPressed:(id)sender {
    if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Add Overlay"])
        [_buttonAddOverlay setTitle:@"Overlay Added" forState:UIControlStateNormal];
    else
        [_buttonAddOverlay setTitle:@"Add Overlay" forState:UIControlStateNormal];
}

- (IBAction)textPressed:(id)sender {
    
}

- (IBAction)closeView:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end