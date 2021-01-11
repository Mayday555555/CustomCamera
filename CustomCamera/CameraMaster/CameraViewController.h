//
//  CameraViewController.h
//  TomDemo
//
//  Created by tom on 2020/12/17.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CustomCameraManager.h"
NS_ASSUME_NONNULL_BEGIN


@interface CameraViewController : UIViewController
@property (nonatomic,assign) CameraMode cameraMode;
@property (nonatomic,assign) AVCaptureSessionPreset videoQuality;//默认：AVCaptureSessionPreset1920x1080
@property (nonatomic,assign) NSTimeInterval maxVideoDuration;//视频最长录制时间，默认不限制。
- (instancetype)initWithCameraMode:(CameraMode)cameraMode;

@property (nonatomic, copy  ) void(^dataBlock)(NSData * _Nullable imageData,NSData * _Nullable videoData);
@end

NS_ASSUME_NONNULL_END
