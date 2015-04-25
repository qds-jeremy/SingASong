//
//  SetMusicStartTimeViewController.h
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SetMusicStartTimeViewController : UIViewController <AVAudioPlayerDelegate>

@property (assign, nonatomic) BOOL isPlaying;

@property (strong, nonatomic) NSURL *songURL;

@property (strong, nonatomic) AVAsset *assetSongNewStart;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) NSDate *previousFireDate;

@property (strong, nonatomic) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UILabel *labelTimeStamp;

@property (weak, nonatomic) IBOutlet UIButton *buttonPlayPause;

@property (weak, nonatomic) IBOutlet UISlider *slider;

@end
