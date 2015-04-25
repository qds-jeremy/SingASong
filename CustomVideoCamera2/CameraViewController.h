#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import <AssetsLibrary/AssetsLibrary.h>		//<<Can delete if not storing videos to the photo library.  Delete the assetslibrary framework too requires this)

#define CAPTURE_FRAMES_PER_SECOND		20

@interface CameraViewController : UIViewController <AVCaptureFileOutputRecordingDelegate> {
    BOOL isRecording;
    
    AVCaptureSession *session;
    AVCaptureMovieFileOutput *output;
    AVCaptureDeviceInput *deviceInput;
}

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;

@property (assign, nonatomic) BOOL isUsingHeadset;

@property (strong, nonatomic) AVAsset *assetSong;
@property (strong, nonatomic) AVPlayer *audioPlayer;

@property (strong, nonatomic) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIView *viewForPreview;
@property (weak, nonatomic) IBOutlet UILabel *labelCountdown;
@property (weak, nonatomic) IBOutlet UIButton *buttonStartStop;

- (void)cameraSetOutputProperties;

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;

- (IBAction)startStopButtonPressed:(id)sender;
- (IBAction)cameraToggleButtonPressed:(id)sender;

@end