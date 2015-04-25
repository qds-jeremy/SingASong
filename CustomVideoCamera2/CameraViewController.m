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
}

- (void)orientaionDidChange:(UIInterfaceOrientation)interfaceOrientation {
    
    if (isRecording)
        return;
    
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    } else if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    
}


//********** VIEW WILL APPEAR **********
//View about to be added to the window (called each time it appears)
//Occurs after other view's viewWillDisappear
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    isRecording = NO;
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
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    UInt32 doSetProperty = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
}

- (void)startSongAndRecording {
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:_assetSong];
    _audioPlayer = [[AVPlayer alloc]initWithPlayerItem:playerItem];

    [_audioPlayer seekToTime:kCMTimeZero];
    [_audioPlayer play];
    
    [self startRecording];
    
}

- (void)checkForHeadset {
    UInt32 routeSize = sizeof (CFStringRef); CFStringRef route;
    AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);
    
    //NSLog(@"Error >>>>>>>>>> :%@", error);
    /* Known values of route:
     "Headset"
     "Headphone"
     "Speaker"
     "SpeakerAndMicrophone"
     "HeadphonesAndMicrophone"
     "HeadsetInOut"
     "ReceiverAndMicrophone"
     "Lineout" */
    
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
}




//---------------------------------
//----- SETUP CAPTURE SESSION -----
//---------------------------------
- (void)setupCaptureSession {
    NSLog(@"Setting up capture session");
    session = [[AVCaptureSession alloc] init];
    
    //----- ADD INPUTS -----
    NSLog(@"Adding video input");
    
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
    NSLog(@"Adding audio input");
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        [session addInput:audioInput];
    }
    
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:session]];
    
    [previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait]; //<<SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
    [[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    //ADD MOVIE FILE OUTPUT
    NSLog(@"Adding movie file output");
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
    NSLog(@"Setting image quality");
//    [session setSessionPreset:AVCaptureSessionPresetMedium];
//    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480])		//Check size based configs are supported before setting them
    [session setSessionPreset:AVCaptureSessionPreset640x480];
    
    
    
    //----- DISPLAY THE PREVIEW LAYER -----
    //Display it full screen under out view controller existing controls
    NSLog(@"Display the preview layer");
    CGRect layerRect = _viewForPreview.layer.bounds;
    [previewLayer setBounds:layerRect];
    [previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    //[[[self view] layer] addSublayer:[[self CaptureManager] previewLayer]];
    //We use this instead so it goes on a layer behind our UI controls (avoids us having to manually bring each control to the front):
    UIView *CameraView = [[UIView alloc] init];
    [_viewForPreview addSubview:CameraView];
    //    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:previewLayer];
    
    
    //----- START THE CAPTURE SESSION RUNNING -----
    [session startRunning];
}

//********** CAMERA SET OUTPUT PROPERTIES **********
- (void) cameraSetOutputProperties
{
    //SET THE CONNECTION PROPERTIES (output properties)
    AVCaptureConnection *CaptureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([CaptureConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [CaptureConnection setVideoOrientation:orientation];
    }
    
    //Set frame rate (if requried)
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
    if (CaptureConnection.supportsVideoMinFrameDuration)
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    if (CaptureConnection.supportsVideoMaxFrameDuration)
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
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
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        // 3 - Audio track
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
        
        if (_isUsingHeadset) {
            // 4 - Music track
            if (_assetSong != nil) {
                AVMutableCompositionTrack *musicTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:2];
                [musicTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[_assetSong tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
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
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self exportDidFinish:exporter];
            });
        }];
        
        
    }
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
    
}

- (IBAction)closeView:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end