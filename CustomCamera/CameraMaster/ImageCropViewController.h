//
//  ImageCropViewController.h
//  CYImageCrop
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageCropViewController : UIViewController
// 旋转角度
@property (nonatomic, assign) NSInteger angle;
/// 原图
@property (nonatomic,strong) UIImage *originImage;
/// 需要无动画效果退出页面
@property (nonatomic,assign) BOOL needNoAnimationDismiss;
/// 背景色 默认 黑色
@property (nonatomic,strong) UIColor *backgroundColor;
/// 返回裁剪图片block
@property (nonatomic, copy  ) void(^imageCropBlock)(UIImage *image);
@end

NS_ASSUME_NONNULL_END
