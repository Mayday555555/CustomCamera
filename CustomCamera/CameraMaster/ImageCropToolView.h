//
//  ImageCropToolView.h
//  CYImageCrop
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageCropToolView : UIView
@property(nonatomic, assign,) BOOL deviceRatate;
/// 返回block
@property (nonatomic, copy) void(^cancelBlock)(void);
/// 确认block
@property (nonatomic, copy) void(^confirmBlock)(void);
/// 旋转block
@property (nonatomic, copy) void(^ratateBlock)(void);
@end

NS_ASSUME_NONNULL_END
