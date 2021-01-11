//
//  UIImageView+Crop.h
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 XZ. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CropView.h"

@interface UIImageView (Crop)

/** 裁剪视图 */
@property (nonatomic, strong)CropView * cropView;

/** 根据缩放类型显示裁剪视图 */
- (void)showCropViewWithType:(CropScaleType)type;

/** 隐藏裁剪视图 */
- (void)hideCropViewWithAnimated:(BOOL)animated;

/** 计算出 imageView 中显示内容的尺寸 */
- (CGRect)contentFrame;

/** 返回实际裁剪区域的 frame  */
@property (nonatomic, assign, readonly)CGRect cropFrame;
/** 返回实际裁剪区域占据整个视图的位置比例（0，0，0，0）是左上角 （1，1，1，1）是右下角*/
@property (nonatomic, assign, readonly)CGRect cropFrameRatio;


/** 设置缩放类型 */
- (void)setScaleType:(CropScaleType)scaleType;

/** 设置每次拖拽裁剪框后的回调 */
- (void)setComplectionHandler:(void (^)(void))complectionHandler;

- (void)updateLayoutCropView;


@end

