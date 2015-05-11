//
//  ExportCapture.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "ExportCapture.h"
#import "PlayVideoViewController.h"

@implementation ExportCapture

- (void)addOverlayForVideoAtURL:(NSURL *)videoURL addOverlay:(BOOL)willAddOverlay addText:(BOOL)willAddText {
    AVAsset *assetCaptured = [AVAsset assetWithURL:videoURL];
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 2 - Create video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    // 3 - Audio track
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetCaptured.duration) ofTrack:[[assetCaptured tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
    audioTrack.preferredVolume = 10;
    
    // 6 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
    NSURL *exportURL = [NSURL fileURLWithPath:myPathDocs];
    
    // 7 - Create exporter
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
    exportSession.outputURL = exportURL;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self exportDidFinish:exportSession];

        });
    }];
}

//- (void)addOverlayForVideoAtURL:(NSURL *)videoURL addOverlay:(BOOL)willAddOverlay addText:(BOOL)willAddText {
//    AVAsset *asset = [AVAsset assetWithURL:videoURL];
//    if (!asset)
//        NSLog(@"asset is nil");
//
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//
//    // 2 - Create video track
//    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
//    
//    // 3 - Audio track
//    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
//    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
//    
////    // 4 - Create AVMutableVideoCompositionInstruction
////    AVMutableVideoComposition *videoComp = [AVMutableVideoComposition videoComposition];
////    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
////    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
////    
////    //  5 Add animation overlays
////    BOOL addAnimationInstructionLayer = NO;
////    CALayer *parentLayer = [CALayer layer];
////    CALayer *videoLayer = [CALayer layer];
////    [parentLayer addSublayer:videoLayer];
////    //        CGSize videoSize = [[[assetCaptured tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
////    CGSize videoSize = [videoTrack naturalSize];
////    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
////    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
////    
////    if (willAddOverlay) {
////        
////        addAnimationInstructionLayer = YES;
////        UIImage *insideBorderImage = [UIImage imageNamed:@"In_Video_Border.png"];
////        CALayer *aLayer = [CALayer layer];
////        aLayer.contents = (id)insideBorderImage.CGImage;
////        aLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
////        [parentLayer addSublayer:aLayer];
////        
////    }
////    
////    if (willAddText) {
////        
////        addAnimationInstructionLayer = YES;
////        CATextLayer *text = [CATextLayer layer];
////        text.string = @"Put In Text Here";
////        text.frame = CGRectMake(100, 200, 320, 50);
////        CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
////        text.font = font;
////        text.fontSize = 40;
////        text.foregroundColor = [UIColor whiteColor].CGColor;
////        [text display];
////        [parentLayer addSublayer:text];
////        
////    }
////    
////        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
////        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
////        
//////        BOOL isPortrait = NO;
//////        if (_filmedOrientationOfScreen == 4) {
//////            //                CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2 * 2);
//////            //                [layerInstruction setTransform:transform atTime:kCMTimeZero];
//////        } else if (_filmedOrientationOfScreen == 1) {
//////            //                CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
//////            //                [layerInstruction setTransform:transform atTime:kCMTimeZero];
//////            isPortrait = YES;
//////        }
////        
//////        CGSize naturalSize;
//////        if(isPortrait){
//////            naturalSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
//////        } else {
//////            naturalSize = videoTrack.naturalSize;
//////        }
////        
////        videoComp.renderSize = videoSize;
////        videoComp.frameDuration = CMTimeMake(1, 30);
////        videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
////        mainInstruction.layerInstructions = @[ layerInstruction ];
////        videoComp.instructions = [NSArray arrayWithObject: mainInstruction];
//    
//        // 7 - Create exporter
//        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
//        exportSession.outputURL = videoURL;
////        exportSession.videoComposition = videoComp;
//        exportSession.shouldOptimizeForNetworkUse = YES;
//        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
//        
//        [exportSession exportAsynchronouslyWithCompletionHandler:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//            [self exportDidFinish:exportSession];
//                
//            });
//        }];
//
//}

- (void)exportDidFinish:(AVAssetExportSession *)exportSession {
    
    NSURL *outputURL = exportSession.outputURL;
    
    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
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
                
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"did not get true for AVAssetExportSessionStatusCompleted" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    }
}

@end
