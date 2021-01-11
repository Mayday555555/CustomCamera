//
//  CameraNavigationController.h
//  TomDemo
//
//  Created by tom on 2020/12/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraNavigationController : UINavigationController
///  初始化仅使用裁剪功能
- (instancetype)initWithImage:(UIImage *)image;
/// 初始化自定义拍照页面+裁剪功能
- (instancetype)initWithTakePictures;
/// 初始化拍照/摄像切换页面
- (instancetype)initWithPictureAndVideo;
//视频拍摄
- (instancetype)initWithVideo;
/// 返回裁剪图片block
@property (nonatomic, copy  ) void(^imageCropBlock)(UIImage *image);
/// 返回拍照图片block
@property (nonatomic, copy  ) void(^takeImageBlock)(UIImage *image);
/// 返回图片/视频NSData数据 block
@property (nonatomic, copy  ) void(^dataBlock)(NSData * _Nullable imageData,NSData * _Nullable videoData);
@end

NS_ASSUME_NONNULL_END
