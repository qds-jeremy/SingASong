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

- (void)exportComplete;

@end

@interface ExportCapture : NSObject

//@property (assign, nonatomic) id <ExportCaptureProtocal> delegate;

//- (void)exportDidFinish:(AVAssetExportSession *)exportSession;

@end
