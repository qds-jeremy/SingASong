#import "CameraViewController.h"

@implementation CameraViewController

@synthesize previewLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//********** VIEW DID LOAD **********
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientaionDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self allowMusicToPlay];
    
    [self setupCaptureSession];
    
    [self setupAudioPlayer];
    
}

- (void)orientaionDidChange:(UIInterfaceOrientation)interfaceOrientation {
    
    if (isRecording)
        return;
    
    [self cameraSetOutputProperties];
    
    [self sizeCameraForOrientation];
    
}


//********** VIEW WILL APPEAR **********
//View about to be added to the window (called each time it appears)
//Occurs after other view's viewWillDisappear
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    isRecording = NO;
}

- (void)setupAudioPlayer {
    
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:_songURL error:nil];
    
    _audioPlayer.currentTime = CMTimeGetSeconds(_songStartTime);
    
    _audioPlayer.delegate = self;
    
    [_audioPlayer prepareToPlay];

}

- (void)startCountdown {
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimerLabel) userInfo:nil repeats:YES];
    
    [_timer fire];
    
}

- (void)updateTimerLabel {
    
    int countdownNumber = _labelCountdown.text.intValue;
    countdownNumber--;
    
    if (countdownNumber > 0) {
    _labelCountdown.text = [NSString stringWithFormat:@"%i", countdownNumber];
    } else {
        
        [_labelCountdown setHidden:YES];
        [_timer invalidate];
        [self checkForHeadset];
        [self startSongAndRecording];
        
    }
    
}

- (void)allowMusicToPlay {
    
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    NSError *setCategoryError = nil;
    
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error: nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
//    if (![audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&setCategoryError]) {
//        NSLog(@"audioSessionMixError: %@ %@", setCategoryError, [setCategoryError userInfo]);
//    }
    
}

- (void)startSongAndRecording {

//    dispatch_queue_t myQueue = dispatch_queue_create("AudioVideoRecordQueue",NULL);
//    dispatch_async(myQueue, ^{
//    
//        [_audioPlayer play];
//        [self startRecording];
//    
//    });
    
    [_audioPlayer play];
//    [_audioPlayer pause];
    [self startRecording];
    
}

- (void)checkForHeadset {
    
    _isUsingHeadset = NO;
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones] || [[desc portType] isEqualToString:@"Headphones"])
            _isUsingHeadset = YES;
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
}

//---------------------------------
//----- SETUP CAPTURE SESSION -----
//---------------------------------
- (void)setupCaptureSession {
//    NSLog(@"Setting up capture session");
    session = [[AVCaptureSession alloc] init];
    
    //----- ADD INPUTS -----
//    NSLog(@"Adding video input");
    
    //ADD VIDEO INPUT
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice)
    {
        NSError *error;
        deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([session canAddInput:deviceInput])
                [session addInput:deviceInput];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
    
    //ADD AUDIO INPUT
//    NSLog(@"Adding audio input");
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        [session addInput:audioInput];
    }
    
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
//    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:session]];
    
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait]; //<<SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
    [[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    //ADD MOVIE FILE OUTPUT
//    NSLog(@"Adding movie file output");
    output = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    output.maxRecordedDuration = maxDuration;
    
    output.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([session canAddOutput:output])
        [session addOutput:output];
    
    //SET THE CONNECTION PROPERTIES (output properties)
    [self cameraSetOutputProperties];			//(We call a method as it also has to be done after changing camera)
    
    
    
    //----- SET THE IMAGE QUALITY / RESOLUTION -----
    //Options:
    //	AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
    //	AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
    //	AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
    //	AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
    //	AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
    //	AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
//    NSLog(@"Setting image quality");
//    [session setSessionPreset:AVCaptureSessionPresetMedium];
//    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480])		//Check size based configs are supported before setting them
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    
    
    
    //----- DISPLAY THE PREVIEW LAYER -----
    //Display it full screen under out view controller existing controls
//    NSLog(@"Display the preview layer");

    [self sizeCameraForOrientation];

    //[[[self view] layer] addSublayer:[[self CaptureManager] previewLayer]];
    //We use this instead so it goes on a layer behind our UI controls (avoids us having to manually bring each control to the front):
    UIView *CameraView = [[UIView alloc] init];
    [_viewForPreview addSubview:CameraView];
    //    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:previewLayer];
    
    //----- START THE CAPTURE SESSION RUNNING -----
    [session startRunning];
}

- (void)sizeCameraForOrientation {
    _viewForPreview.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    CGRect layerRect = _viewForPreview.layer.bounds;
    [previewLayer setBounds:layerRect];
    [previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
}

//********** CAMERA SET OUTPUT PROPERTIES **********
- (void) cameraSetOutputProperties
{
    //SET THE CONNECTION PROPERTIES (output properties)
    AVCaptureConnection *CaptureConnection = [output connectionWithMediaType:AVMediaTypeVideo];

    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [CaptureConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        [CaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        [CaptureConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        
    }

    
//    //Set landscape (if required)
//    if ([CaptureConnection isVideoOrientationSupported])
//    {
//        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
//        [CaptureConnection setVideoOrientation:orientation];
//    }

    
//    //Set frame rate (if requried)
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
//    
//    if (CaptureConnection.supportsVideoMinFrameDuration)
//        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    if (CaptureConnection.supportsVideoMaxFrameDuration)
//        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
}

//********** GET CAMERA IN SPECIFIED POSITION IF IT EXISTS **********
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == position)
        {
            return Device;
        }
    }
    return nil;
}



//********** CAMERA TOGGLE **********
- (IBAction)cameraToggleButtonPressed:(id)sender
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)		//Only do if device has multiple cameras
    {
        NSLog(@"Toggle camera");
        NSError *error;
        //AVCaptureDeviceInput *videoInput = [self videoInput];
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[deviceInput device] position];
        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil)
        {
            [session beginConfiguration];		//We can now change the inputs and output configuration.  Use commitConfiguration to end
            [session removeInput:deviceInput];
            if ([session canAddInput:NewVideoInput])
            {
                [session addInput:NewVideoInput];
                deviceInput = NewVideoInput;
            }
            else
            {
                [session addInput:deviceInput];
            }
            
            //Set the connection properties again
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
            
//            CATextLayer *titleLayer = [CATextLayer layer];
//            titleLayer.string = @"Text goes here";
//            titleLayer.font = CFBridgingRetain(@"Helvetica");
//            titleLayer.fontSize = 20;
//            //?? titleLayer.shadowOpacity = 0.5;
//            titleLayer.alignmentMode = kCAAlignmentCenter;
//            titleLayer.bounds = CGRectMake(100, 100, 100, 100); //You may need to adjust this for proper display
//            [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
            
            CATextLayer *text = [CATextLayer layer];
            text.string = @"Your Text";
            text.frame = CGRectMake(0, 0, 320, 50);
            CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
            text.font = font;
            text.fontSize = 20;
            text.foregroundColor = [UIColor whiteColor].CGColor;
            [text display];
            [parentLayer addSublayer:text];
            
            
            AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
            AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            
            
            AVMutableVideoCompositionLayerInstruction *orientationInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            AVAssetTrack *firstAssetTrack = [[assetCaptured tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            UIImageOrientation firstAssetOrientation_  = UIImageOrientationUp;
            BOOL isFirstAssetPortrait_  = NO;
            CGAffineTransform firstTransform = firstAssetTrack.preferredTransform;
            if (firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0) {
                firstAssetOrientation_ = UIImageOrientationLeft;
                isFirstAssetPortrait_ = YES;
            }
            if (firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0) {
                firstAssetOrientation_ =  UIImageOrientationLeft;
                isFirstAssetPortrait_ = YES;
            }
            if (firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0) {
                firstAssetOrientation_ =  UIImageOrientationUp;
            }
            if (firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0) {
                firstAssetOrientation_ = UIImageOrientationDown;
            }
            [orientationInstruction setTransform:assetCaptured.preferredTransform atTime:kCMTimeZero];
            [orientationInstruction setOpacity:0.0 atTime:assetCaptured.duration];
//
//            instruction.layerInstructions = @[ layerInstruction, firstlayerInstruction ];
            
            videoComp = [AVMutableVideoComposition videoComposition];
            videoComp.renderSize = videoSize;
            videoComp.frameDuration = CMTimeMake(1, 30);
            videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
            mainInstruction.layerInstructions = @[ layerInstruction, orientationInstruction ];
            videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
            
            CGSize naturalSizeFirst, naturalSizeSecond;
            if(isFirstAssetPortrait_){
                naturalSizeFirst = CGSizeMake(assetCaptured.naturalSize.height, assetCaptured.naturalSize.width);
            } else {
                naturalSizeFirst = assetCaptured.naturalSize;
            }
            
            float renderWidth, renderHeight;
            if(naturalSizeFirst.width > naturalSizeSecond.width) {
                renderWidth = naturalSizeFirst.width;
            } else {
                renderWidth = naturalSizeSecond.width;
            }
            if(naturalSizeFirst.height > naturalSizeSecond.height) {
                renderHeight = naturalSizeFirst.height;
            } else {
                renderHeight = naturalSizeSecond.height;
            }
            
            videoComp.renderSize = CGSizeMake(renderWidth, renderHeight);
            
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

//- (void)addAnimation {
//
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:videoName ofType:ext];
//
//    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:filePath]  options:nil];
//    
//    AVMutableComposition* mixComposition = [AVMutableComposition composition];
//    
//    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    
//    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    
//    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
//    
//    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
//    
//    CGSize videoSize = [clipVideoTrack naturalSize];
//    
//    UIImage *myImage = [UIImage imageNamed:@"29.png"];
//    CALayer *aLayer = [CALayer layer];
//    aLayer.contents = (id)myImage.CGImage;
//    aLayer.frame = CGRectMake(videoSize.width - 65, videoSize.height - 75, 57, 57);
//    aLayer.opacity = 0.65;
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:aLayer];
//    
//    CATextLayer *titleLayer = [CATextLayer layer];
//    titleLayer.string = @"Text goes here";
//    titleLayer.font = CFBridgingRetain(@"Helvetica");
//    titleLayer.fontSize = videoSize.height / 6;
//    //?? titleLayer.shadowOpacity = 0.5;
//    titleLayer.alignmentMode = kCAAlignmentCenter;
//    titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display
//    [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
//    
//    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
//    videoComp.renderSize = videoSize;
//    videoComp.frameDuration = CMTimeMake(1, 30);
//    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//    
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
//    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
//    videoComp.instructions = [NSArray arrayWithObject: instruction];
//    
//    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
//    assetExport.videoComposition = videoComp;
//    
//}
//
//- (void)addAnimation2
//{
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:videoName ofType:ext];
//    
//    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:filePath]  options:nil];
//    
//    AVMutableComposition* mixComposition = [AVMutableComposition composition];
//    
//    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    
//    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    
//    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
//    
//    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
//    
//    CGSize videoSize = [clipVideoTrack naturalSize];
//    
//    UIImage *myImage = [UIImage imageNamed:@"29.png"];
//    CALayer *aLayer = [CALayer layer];
//    aLayer.contents = (id)myImage.CGImage;
//    aLayer.frame = CGRectMake(videoSize.width - 65, videoSize.height - 75, 57, 57);
//    aLayer.opacity = 0.65;
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:aLayer];
//    
//    CATextLayer *titleLayer = [CATextLayer layer];
//    titleLayer.string = @"Text goes here";
//    titleLayer.font = CFBridgingRetain(@"Helvetica");
//    titleLayer.fontSize = videoSize.height / 6;
//    //?? titleLayer.shadowOpacity = 0.5;
//    titleLayer.alignmentMode = kCAAlignmentCenter;
//    titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display
//    [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
//    
//    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
//    videoComp.renderSize = videoSize;
//    videoComp.frameDuration = CMTimeMake(1, 30);
//    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//    
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
//    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
//    videoComp.instructions = [NSArray arrayWithObject: instruction];
//    
//    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
//    assetExport.videoComposition = videoComp;
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString* VideoName = [NSString stringWithFormat:@"%@/mynewwatermarkedvideo.mp4",documentsDirectory];
//    
//    
//    //NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:VideoName];
//    NSURL *exportUrl = [NSURL fileURLWithPath:VideoName];
//    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:VideoName])
//    {
//        [[NSFileManager defaultManager] removeItemAtPath:VideoName error:nil];
//    }
//    
//    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
//    assetExport.outputURL = exportUrl;
//    assetExport.shouldOptimizeForNetworkUse = YES;
//    
//    //[strRecordedFilename setString: exportPath];
//    
//    [assetExport exportAsynchronouslyWithCompletionHandler:
//     ^(void ) {
//         dispatch_async(dispatch_get_main_queue(), ^{
//             [self exportDidFinish:assetExport];
//         });
//     }
//     ];
//}

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

- (AVMutableVideoComposition *) getVideoComposition:(AVAsset *)asset composition:( AVMutableComposition*)composition{
    BOOL isPortrait_ = [self isVideoPortrait:asset];
    
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    
    AVMutableVideoCompositionLayerInstruction *layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    CGAffineTransform transform = videoTrack.preferredTransform;
    [layerInst setTransform:transform atTime:kCMTimeZero];
    
    
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    
    CGSize videoSize = videoTrack.naturalSize;
    if(isPortrait_) {
        NSLog(@"video is portrait ");
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMake(1,30);
    videoComposition.renderScale = 1.0;
    return videoComposition;
}

- (BOOL) isVideoPortrait:(AVAsset *)asset{
    BOOL isPortrait = FALSE;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks    count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        CGAffineTransform t = videoTrack.preferredTransform;
        // Portrait
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            isPortrait = YES;
        }
        // PortraitUpsideDown
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
            
            isPortrait = YES;
        }
        // LandscapeRight
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            isPortrait = FALSE;
        }
        // LandscapeLeft
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            isPortrait = FALSE;
        }
    }
    return isPortrait;
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