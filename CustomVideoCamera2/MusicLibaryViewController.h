//
//  MusicLibaryViewController.h
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/24/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface MusicLibaryViewController : UIViewController <MPMediaPickerControllerDelegate>

@property (strong, nonatomic) NSURL *songURL;

@end
