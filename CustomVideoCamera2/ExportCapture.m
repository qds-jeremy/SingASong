//
//  ExportCapture.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "ExportCapture.h"
#import "Initialize.h"

@implementation ExportCapture

@synthesize preferredTransform, filmedOrientation;

- (void)addOverlayForVideoAtURL:(NSURL *)videoURL addOverlay:(BOOL)willAddOverlay addText:(BOOL)willAddText  {
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:videoURL  options:nil];
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    
    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    CGSize videoSize = [clipVideoTrack naturalSize];
    
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);

    if (filmedOrientation == 1) {
        //        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
        //        videoTrack.preferredTransform = rotationTransform;
//        parentLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(-M_PI_2));
    } else if (filmedOrientation == 4) {
//        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI_2 * 2);
//        videoTrack.preferredTransform = rotationTransform;
                parentLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2 * 2));
    }
    
    CALayer *videoLayer = [CALayer layer];
    
    //  Add image overlay
    UIImage *imageOverlay = [UIImage imageNamed:@"In_Video_Border.png"];
    CALayer *imageLayer = [CALayer layer];
    imageLayer.contents = (id)imageOverlay.CGImage;
    imageLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:imageLayer];
    
    //  Add text overlay
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = @"Hi";
    titleLayer.font = CFBridgingRetain(@"Helvetica");
    titleLayer.fontSize = videoSize.height / 6;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    if (filmedOrientation == 1)
        titleLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2));
    else if (filmedOrientation == 4)
        titleLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(M_PI_2 * 2));
    
    titleLayer.frame = CGRectMake(videoSize.height / 2 - videoSize.height / 4, videoSize.width / 2 - videoSize.width / 4, videoSize.height / 4, videoSize.width / 4);
    [parentLayer addSublayer:titleLayer];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
//    if (filmedOrientation == 1) {
//        CGAffineTransform tranformMake = CGAffineTransformMakeRotation(M_PI_2);
//        [layerInstruction setTransform:tranformMake atTime:kCMTimeZero];
//        videoComposition.renderSize = CGSizeMake(parentLayer.bounds.size.height, parentLayer.bounds.size.width);
//    }
    
    // 6 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *videosDirectory = [documentsDirectory stringByAppendingPathComponent:@"/Videos"];
    NSString *exportPath = [videosDirectory stringByAppendingPathComponent:[[Initialize new] getFileNameForVideo]];
    
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];

    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.outputURL = exportURL;
    assetExport.shouldOptimizeForNetworkUse = YES;
    assetExport.videoComposition = videoComposition;
    
    //[strRecordedFilename setString: exportPath];
    
    [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
         dispatch_async(dispatch_get_main_queue(),^{

             if (filmedOrientation != 1)
                 [self exportDidFinish:assetExport];
             else
                 [self reorientVideoWithURL:exportURL originalPreferredRotation:preferredTransform filmedInOrientation:filmedOrientation];
             
         });
     }];
}

//  Rotate back to portrait
- (void)reorientVideoWithURL:(NSURL *)videoURL originalPreferredRotation:(CGAffineTransform)preferredTransform filmedInOrientation:(int)filmedOrientation {

    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 2 - Create video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    // 3 - Audio track
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
    
//    // 3.1 - Create AVMutableVideoCompositionInstruction
//    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
//    
//    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
//    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//
//    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
//    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];
//    
//    // 3.3 - Add instructions
//    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
//    
//    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//    
//    CGSize naturalSize;
//    
////    if(isVideoAssetPortrait_){
//        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
////    } else {
////        naturalSize = videoAssetTrack.naturalSize;
////    }
//    
//    float renderWidth, renderHeight;
//    renderWidth = naturalSize.width;
//    renderHeight = naturalSize.height;
//    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    [videoTrack setPreferredTransform:_captureAsset.preferredTransform];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = videoURL;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        dispatch_async(dispatch_get_main_queue(),^{
            
            [self exportDidFinish:exportSession];
            
        });
    }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
    NSURL *exportUrl = session.outputURL;
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl]) {
        [library writeVideoAtPathToSavedPhotosAlbum:exportUrl completionBlock:^(NSURL *assetURL, NSError *error) {
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

@end
