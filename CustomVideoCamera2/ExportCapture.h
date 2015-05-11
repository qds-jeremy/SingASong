//
//  ExportCapture.h
//  CustomVideoCamera2
//
//  Created by Jeremy on 5/5/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol ExportCaptureProtocal <NSObject>

- (void)allExportSessionsComplete;

@end

@interface ExportCapture : NSObject

@property (assign, nonatomic) id <ExportCaptureProtocal> delegate;

@property (assign, nonatomic) int filmedOrientation;

@property (assign, nonatomic) CGAffineTransform preferredTransform;

@property (strong, nonatomic) AVAsset *captureAsset;

- (void)addOverlayForVideoAtURL:(NSURL *)videoURL addOverlay:(BOOL)willAddOverlay addText:(BOOL)willAddText;

- (void)exportDidFinish:(AVAssetExportSession*)session;

@end
