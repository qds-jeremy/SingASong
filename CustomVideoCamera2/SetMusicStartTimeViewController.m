//
//  SetMusicStartTimeViewController.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "SetMusicStartTimeViewController.h"
#import "CameraViewController.h"

@interface SetMusicStartTimeViewController ()

@end

@implementation SetMusicStartTimeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setSongToPlayer];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    CameraViewController *vc = segue.destinationViewController;
    
//    if ([segue.identifier isEqualToString:@"nextWithSong"]) {
    
        vc.songURL = _songURL;
    
    vc.songStartTime = CMTimeMakeWithSeconds(_slider.value, 1);
        
//    } else {
//    
//        vc.songURL = [AVAsset assetWithURL:_songURL];
//        
//    }
    
}

- (void)setSongToPlayer {
    
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:_songURL error:nil];
    
    _audioPlayer.delegate = self;
    
    [_audioPlayer prepareToPlay];
    
    _slider.maximumValue = _audioPlayer.duration;
    
}

- (void)updateTime {
    
    float floatSeconds;
    
    if (_isPlaying) {
        floatSeconds = _audioPlayer.currentTime;
        _slider.value = floatSeconds;
    } else
        floatSeconds = _slider.value;
    
    int wholeSeconds = floatSeconds;
    int hours = wholeSeconds / 60 / 60;
    int minutes = wholeSeconds / 60 - hours * 60;
    int seconds = wholeSeconds - minutes * 60;
    int tenths = (floatSeconds - wholeSeconds) * 10;
    
    _labelTimeStamp.text = [NSString stringWithFormat:@"%i:%02d:%02d:%i", hours, minutes, seconds, tenths];
    
}

- (void)playSong {
    
    _isPlaying = YES;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    [_timer setFireDate:_previousFireDate];
    
    [_audioPlayer play];
    
    [_buttonPlayPause setTitle:@"Pause" forState:UIControlStateNormal];
    
}

- (void)pauseSong {
    
    _isPlaying = NO;
    
    _previousFireDate = _timer.fireDate;
    
    [_audioPlayer pause];
    
    [_buttonPlayPause setTitle:@"Play" forState:UIControlStateNormal];
    
}

- (void)playScrubPreview {
    
    [_audioPlayer pause];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(endScrubPreview) object:nil];
    
    [_audioPlayer play];
    
    [self performSelector:@selector(endScrubPreview) withObject:nil afterDelay:0.4];
    
}

- (void)endScrubPreview {
    
    [_audioPlayer pause];
    
    _audioPlayer.currentTime = _slider.value;
    
}

- (IBAction)sliderMoved:(id)sender {
    
    [self updateTime];
    
    _audioPlayer.currentTime = _slider.value;
    
}

- (IBAction)scrubLeftPressed:(id)sender {

    [self updateTime];
    
    _slider.value = _slider.value - 0.1;
    
    _audioPlayer.currentTime = _slider.value;
    
    [self playScrubPreview];

}

- (IBAction)scrubRightPressed:(id)sender {

    [self updateTime];
    
    _slider.value = _slider.value + 0.1;
    
    _audioPlayer.currentTime = _slider.value;

    [self playScrubPreview];
    
}

- (IBAction)playPressed:(id)sender {
    
    if (_isPlaying) {
        
        [self pauseSong];
        
    } else {
        
        [self playSong];

    }
}

- (IBAction)backPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
