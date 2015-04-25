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
    
    NSError *error;
    
    _avAudioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:_songURL error:&error];
    
    _avAudioPlayer.delegate = self;
    
    [_avAudioPlayer prepareToPlay];
    
    [_avAudioPlayer play];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    CameraViewController *vc = segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"nextWithSong"]) {
        
        vc.assetSong = _assetSongNewStart;
        
    } else {
    
        vc.assetSong = [AVAsset assetWithURL:_songURL];
        
    }
    
}

- (void)setSongToPlayer {
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:[AVAsset assetWithURL:_songURL]];
    _audioPlayer = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    [_audioPlayer seekToTime:kCMTimeZero];
    
}

- (IBAction)scrubLeftPressed:(id)sender {

}

- (IBAction)sliderMoved:(id)sender {
    
    CMTime sliderTime = CMTimeMakeWithSeconds(_slider.value, 1);
    [_audioPlayer seekToTime:sliderTime];
    
}

- (void)updateTime:(NSTimer *)timer {
    float currentTime = CMTimeGetSeconds(_audioPlayer.currentTime);
    NSLog(@"currentTime: %f", currentTime);
    
    _slider.value = currentTime;
    
}

- (IBAction)scrubRightPressed:(id)sender {

}

- (IBAction)playPressed:(id)sender {
    
    if (_isPlaying) {
        
        _isPlaying = NO;
        
        _previousFireDate = _timer.fireDate;
        
        [_audioPlayer pause];
        
    } else {
        
        _isPlaying = YES;

        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
        
        [_timer setFireDate:_previousFireDate];
        
        NSLog(@"previousFireDate: %@", _previousFireDate);
        
        [_audioPlayer play];

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
