//
//  CustomCameraManager.h
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/22.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger,CameraMode) {
    CameraModePicture,
    CameraModeVideo,
    CameraModePictureAndVideo
};
NS_ASSUME_NONNULL_BEGIN
@protocol CustomCameraManagerDelegate <NSObject>
- (void)finishVideoWrite:(BOOL)success url:(nullable NSURL *)url isLandscapeRecord:(BOOL)isLandscapeRecord;
- (void)refreshTime:(NSString *)timeStr;
- (void)getPictureData:(NSData *)imageData;
@end
@interface CustomCameraManager : NSObject
@property (nonatomic, strong) AVCaptureDevice               *videoDevice;
@property (nonatomic,assign) NSTimeInterval maxVideoDuration;//视频最长录制时间。
@property (nonatomic, assign)id <CustomCameraManagerDelegate>delegate;
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign)NSInteger videoState;//1未开始 2.正在录视频 3.录制完成
@property (nonatomic, assign)BOOL isPause;//视频录制是否暂停
@property (nonatomic, assign)BOOL discount;//视频录制是否中断
//初始化
- (instancetype)initWithCameraMode:(CameraMode)cameraMode;
//设置画面显示
- (void)addPreviewLayerToView:(UIView *)view;
- (void)setPreviewLayerFrame:(CGRect)rect;
//开始显示画面
- (void)startRunningSession:(BOOL)start;
//拍摄照片
- (BOOL)takePicture;
//开始录制视频
- (void)startVideoWrite;
//暂停录制/继续录制
- (void)pauseAndResumeVideoWrite;
//停止录制视频
- (void)stopVideoWrite;
//重置数据
- (void)resetData;
//设置闪光灯，拍照传flashMode，torchMode传-1； 拍视频传torchMode，flashMode传-1
- (void)setLightOnWithFlashMode:(AVCaptureFlashMode)flashMode torchMode:(AVCaptureTorchMode)torchMode;
//切换前后置摄像头
- (void)changeFrontAndBackCamera;
//把视频转成mp4格式
- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(NSURL *url))handler;
//获取视频封面图
- (void)movieToImageWithUrl:(NSURL *)url handler:(void (^)(UIImage *movieImage))handler;
@end

NS_ASSUME_NONNULL_END
