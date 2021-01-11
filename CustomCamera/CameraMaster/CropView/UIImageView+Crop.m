//
//  UIImageView+Crop.h
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 XZ. All rights reserved.
//

#import "UIImageView+Crop.h"

#import <objc/runtime.h>

const static char *CropViewKey = "CropViewKey";

@implementation UIImageView (Crop)

/** 利用关联对象 添加一个 cropView */
- (CropView *)cropView {
    CropView *cropView = objc_getAssociatedObject(self, CropViewKey);
    if (!cropView) {
        CropView *newCropView = [[CropView alloc] initWithFrame:self.contentFrame];
        self.cropView = newCropView;
        return newCropView;
    }
    return cropView;
}

- (void)setCropView:(CropView *)cropView {
    objc_setAssociatedObject(self, CropViewKey, cropView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/** 计算出 imageView 中显示内容的尺寸 */
- (CGRect)contentFrame {
    
    // 目前只支持这三种缩放类型 UIViewContentModeScaleToFill / UIViewContentModeScaleAspectFill / UIViewContentModeScaleAspectFit
    switch (self.contentMode) {
        case UIViewContentModeScaleAspectFill:
            self.clipsToBounds = YES;
        case UIViewContentModeScaleToFill:
            return self.bounds;
        case UIViewContentModeScaleAspectFit:
        {
            CGFloat x = 0.0;
            CGFloat y = 0.0;
            CGFloat width = 0.0;
            CGFloat height = 0.0;
            CGSize imageSize = self.image.size;
            if ((imageSize.width / imageSize.height) >= (self.frame.size.width / self.frame.size.height)) {
                width = self.frame.size.width;
                height = width / (imageSize.width / imageSize.height);
                x = 0.0;
                y = self.frame.size.height/2.0 - height/2.0;
            } else {
                height = self.frame.size.height;
                width = (imageSize.width / imageSize.height) * height;
                y = 0.0;
                x = self.frame.size.width/2.0 - width/2.0;
            }
            return CGRectMake(x, y, width, height);
        }
        default:
            return CGRectZero;
            break;
    }
}

- (void)layoutSubviews {
    // 因为有可能在布局前访问了 cropView，导致 cropView 的 frame 不准确
    // 所以在 imageView 布局后更新一下 cropView 的 frame
    [super layoutSubviews];
    self.cropView.frame = self.contentFrame;
}

/** 返回实际裁剪区域的 frame */
- (CGRect)cropFrame {
    return self.cropView.cropFrame;
}
- (CGRect)cropFrameRatio {
    return self.cropView.cropFrameRatio;
}

/** 设置裁剪框的类型 默认进行动画 */
- (void)setScaleType:(CropScaleType)scaleType {
    [self setScaleType:scaleType animated:YES];
}

/** 设置裁剪框的类型以及是否进行动画 */
- (void)setScaleType:(CropScaleType)scaleType animated:(BOOL)animated {
    [self.cropView setScaleType:scaleType animated:animated];
}

/** 隐藏裁剪框 */
- (void)hideCropViewWithAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            self.cropView.alpha = 0.0;
        }];
    }else {
        self.cropView.alpha = 0.0;
    }

}

/** 显示裁剪框 */
- (void)showCropView {
    [UIView animateWithDuration:0.15 animations:^{
        self.cropView.alpha = 1.0;
    }];
}


/** 根据类型 显示裁剪框 */
- (void)showCropViewWithType:(CropScaleType)type {
    if (!self.userInteractionEnabled) {
        self.userInteractionEnabled = YES;
    }
    // 如果还没被加到父视图
    if (!self.cropView.superview) {
        [self addSubview:self.cropView];
        [self showCropView];
        [self setScaleType:type animated:NO];
        return;
    } else {
        // 如果还未显示，不用进行缩放时的动画，只要显示整个视图的动画
        if (self.cropView.alpha == 0) {
            [self showCropView];
            [self setScaleType:type animated:NO];
        } else {
            [self setScaleType:type animated:YES];
        }
    }
}

/** 设置每次拖拽裁剪框后的回调 */
- (void)setComplectionHandler:(void (^)(void))complectionHandler {
    self.cropView.completionHandler = complectionHandler;
}

- (void)updateLayoutCropView {
    CGFloat minLenghOfSide = self.cropView.minLenghOfSide;
    CGFloat borderWidth = self.cropView.borderWidth;
    UIColor *borderColor = self.cropView.borderColor;
    UIColor *maskColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.cropView removeFromSuperview];
    self.cropView = [[CropView alloc] initWithFrame:self.contentFrame];
    // 设置缩放边长的最小值，默认为100
    self.cropView.minLenghOfSide = minLenghOfSide;
    // 设置裁剪框边框，默认为 2.0
    self.cropView.borderWidth = borderWidth;
    if (borderColor) {
        self.cropView.borderColor = borderColor;
    }
    // 设置遮罩层颜色，默认为 [UIColor colorWithWhite:0 alpha:0.5]
    self.cropView.maskColor = maskColor;
}


@end
