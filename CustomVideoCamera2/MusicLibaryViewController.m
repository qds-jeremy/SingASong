//
//  MusicLibaryViewController.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 4/24/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "MusicLibaryViewController.h"
#import "SetMusicStartTimeViewController.h"

@interface MusicLibaryViewController ()

@end

@implementation MusicLibaryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _songURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:@"previousSong"]];
        
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    SetMusicStartTimeViewController *vc = segue.destinationViewController;
    
    vc.songURL = _songURL;
    
}

- (IBAction)clearSongPressed:(id)sender {
    
    _songURL = nil;
    
}

- (IBAction)selectSongPressed:(id)sender {
    
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAny];
    
    mediaPicker.delegate = self;
    
    mediaPicker.prompt = @"Select Song To Sing To";
    
    [self presentViewController:mediaPicker animated:YES completion:nil];
    
}

#pragma mark MPMediaPickerControllerDelegate

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    NSArray *selectedSong = [mediaItemCollection items];
    
    if ([selectedSong count] > 0) {
        
        MPMediaItem *songItem = [selectedSong objectAtIndex:0];
        _songURL = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
        
        NSString *urlString = [NSString stringWithFormat:@"%@", _songURL];
        [[NSUserDefaults standardUserDefaults] setValue:urlString forKey:@"previousSong"];
        
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
