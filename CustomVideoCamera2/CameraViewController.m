//
//  CameraViewController.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "CameraViewController.h"

@implementation CameraViewController

@synthesize previewLayer, initialize;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _exportCapture = [ExportCapture new];
    _exportCapture.delegate = self;
    
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
 
        
        // 3.1 - Create AVMutableVideoCompositionInstruction
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, assetCaptured.duration);
        
        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        AVAssetTrack *videoAssetTrack = [[assetCaptured tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
        BOOL isVideoAssetPortrait_  = NO;
        CGAffineTransform videoTransform = videoTrack.preferredTransform;
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
            videoAssetOrientation_ = UIImageOrientationRight;
            isVideoAssetPortrait_ = YES;
        }
        if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
            videoAssetOrientation_ =  UIImageOrientationLeft;
            isVideoAssetPortrait_ = YES;
        }
        if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
            videoAssetOrientation_ =  UIImageOrientationUp;
        }
        if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
            videoAssetOrientation_ = UIImageOrientationDown;
        }
        [videolayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        [videolayerInstruction setOpacity:0.0 atTime:assetCaptured.duration];
        
        // 3.3 - Add instructions
        mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
        
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
        
        CGSize naturalSize;
        if(isVideoAssetPortrait_){
            naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
        } else {
            naturalSize = videoAssetTrack.naturalSize;
        }
        
        float renderWidth, renderHeight;
        renderWidth = naturalSize.width;
        renderHeight = naturalSize.height;
        mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
        mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        
//        //  5 Add animation overlays
//        BOOL addAnimationInstructionLayer = NO;
//        CALayer *parentLayer = [CALayer layer];
//        CALayer *videoLayer = [CALayer layer];
//        [parentLayer addSublayer:videoLayer];
////        CGSize videoSize = [[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
//        CGSize videoSize = [videoTrack naturalSize];
//        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//        
//        if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Overlay Added"]) {
//        
//            addAnimationInstructionLayer = YES;
//            UIImage *insideBorderImage = [UIImage imageNamed:@"In_Video_Border.png"];
//            CALayer *aLayer = [CALayer layer];
//            aLayer.contents = (id)insideBorderImage.CGImage;
//            aLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//            [parentLayer addSublayer:aLayer];
//        
//        }
//        
//        if ([_buttonAddText.titleLabel.text isEqualToString:@"Text Added"]) {
//            
//            addAnimationInstructionLayer = YES;
//            CATextLayer *text = [CATextLayer layer];
//            text.string = @"Put In Text Here";
//            text.frame = CGRectMake(100, 200, 320, 50);
//            CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
//            text.font = font;
//            text.fontSize = 40;
//            text.foregroundColor = [UIColor whiteColor].CGColor;
//            [text display];
//            [parentLayer addSublayer:text];
//            
//        }
        
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
        
        if ([_buttonAddOverlay.titleLabel.text isEqualToString:@"Overlay Added"])
            exporter.videoComposition = mainCompositionInst;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_exportCapture exportDidFinish:exporter];
            });
        }];
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