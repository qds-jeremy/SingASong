//
//  ExportCapture.m
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "ExportCapture.h"

@implementation ExportCapture

- (void)exportDidFinish:(AVAssetExportSession *)exportSession addAnimationLayerForOverlay:(BOOL)hasOverlay forText:(BOOL)hasText {
    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = exportSession.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                NSLog(@"outputURL: %@", outputURL);
                NSLog(@"assetURL: %@", assetURL);
                _exportURL = outputURL;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        if (hasOverlay || hasText) {
                            [self addAnimationLayerForOverlay:hasOverlay forText:hasText];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        }
                    }
                });
            }];
        }
        [_delegate exportComplete];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"did not get true for AVAssetExportSessionStatusCompleted" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];

    }
}

- (void)addAnimationLayerForOverlay:(BOOL)hasOverlay forText:(BOOL)hasText {
    NSLog(@"exportURL: %@", _exportURL);
    AVAsset *asset = [AVAsset assetWithURL:_exportURL];
    
    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
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
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];
    
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
    
    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    
    // 4 - Get path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"FinalVideo-%d.mov",arc4random() % 1000]];
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    // 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportDidFinish:exporter addAnimationLayerForOverlay:NO forText:NO];
        });
    }];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 1 - set up the overlay
    CALayer *overlayLayer = [CALayer layer];
    UIImage *overlayImage = [UIImage imageNamed:@"In_Video_Border.png"];
    
    [overlayLayer setContents:(id)[overlayImage CGImage]];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    // 2 - set up the parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    // 3 - apply magic
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}

//- (void)addAnimationLayerForOverlay:(BOOL)hasOverlay forText:(BOOL)hasText {
//    
////    if (hasOverlay) {
////    UIImage *borderImage = [UIImage imageNamed:@"In_Video_Border.png"];
////    
////    CALayer *backgroundLayer = [CALayer layer];
////    [backgroundLayer setContents:(id)[borderImage CGImage]];
////    backgroundLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////    [backgroundLayer setMasksToBounds:YES];
////    
////    CALayer *videoLayer = [CALayer layer];
////    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////    CALayer *parentLayer = [CALayer layer];
////    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////    [parentLayer addSublayer:backgroundLayer];
////    [parentLayer addSublayer:videoLayer];
////    
////    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
////    }
//    
//    
//    
//    
//    AVAsset *asset = [AVAsset assetWithURL:_exportURL];
//    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
//    // 2 - Video track
//    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
//    
//    // 7 - Create exporter
//    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
//    exporter.outputURL = _exportURL;
//    exporter.outputFileType = AVFileTypeQuickTimeMovie;
//    exporter.shouldOptimizeForNetworkUse = YES;
//    
//    if (asset == nil)
//        NSLog(@"has nil value");
//    if (mixComposition == nil)
//        NSLog(@"has nil value");
//    if (firstTrack == nil)
//        NSLog(@"has nil value");
//    if (exporter == nil)
//        NSLog(@"has nil value");
//    if (exporter.outputURL == nil)
//        NSLog(@"has nil value");
//    if (exporter.outputFileType == nil)
//        NSLog(@"has nil value");
//    
//    [exporter exportAsynchronouslyWithCompletionHandler:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self exportDidFinish:exporter addAnimationLayerForOverlay:NO forText:NO];
//        });
//    }];
//    
//    
//    
//    
//    
//    
////    AVAsset *asset = [AVAsset assetWithURL:_exportURL];
////    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
////    AVMutableCompositionTrack *videoAssetTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
////    [videoAssetTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
////
//////    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//////    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
////    
////    CGSize naturalSize;
////    if (videoAssetTrack.naturalSize.height > videoAssetTrack.naturalSize.width) {
////        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
////    } else {
////        naturalSize = videoAssetTrack.naturalSize;
////    }
////    
////    float renderWidth, renderHeight;
////    renderWidth = naturalSize.width;
////    renderHeight = naturalSize.height;
//////    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
//////    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
//////    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
////    
////    //  5 Add animation overlays
////    CALayer *parentLayer = [CALayer layer];
////    CALayer *videoLayer = [CALayer layer];
////    [parentLayer addSublayer:videoLayer];
////    
////    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////
////    if (hasOverlay) {
////        
////        UIImage *insideBorderImage = [UIImage imageNamed:@"In_Video_Border.png"];
////        CALayer *aLayer = [CALayer layer];
////        aLayer.contents = (id)insideBorderImage.CGImage;
////        aLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
////        [parentLayer addSublayer:aLayer];
//////        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
////    
////    }
////    
////    if (hasText) {
////
////        CATextLayer *text = [CATextLayer layer];
////        text.string = @"Put In Text Here";
////        text.frame = CGRectMake(100, 200, 320, 50);
////        CGFontRef font = CGFontCreateWithFontName((CFStringRef)@"HelveticaNeue-UltraLight");
////        text.font = font;
////        text.fontSize = 40;
////        text.foregroundColor = [UIColor whiteColor].CGColor;
////        [text display];
////        [parentLayer addSublayer:text];
////    }
////    
////    // 6 - Get path
////    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
////    NSString *documentsDirectory = [paths objectAtIndex:0];
////    
////    // 7 - Create exporter
////    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
////    exporter.outputURL = _exportURL;
////    exporter.outputFileType = AVFileTypeQuickTimeMovie;
////    exporter.shouldOptimizeForNetworkUse = YES;
////    
////    [self exportDidFinish:exporter addAnimationLayerForOverlay:NO forText:NO];
//}

@end
