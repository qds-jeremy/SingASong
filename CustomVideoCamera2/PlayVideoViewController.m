//
//  PlayVideoViewController.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/8/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "PlayVideoViewController.h"

@interface PlayVideoViewController ()

@end

@implementation PlayVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:_url];
    [moviePlayer.view setFrame:CGRectMake(40, 197, 240, 160)];
    [moviePlayer prepareToPlay];
    [moviePlayer setShouldAutoplay:NO];
    [self.view addSubview:moviePlayer.view];
    
    NSLog(@"url: %@", _url);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
