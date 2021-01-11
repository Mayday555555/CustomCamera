//
//  CropView.h
//  CropView
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CropScaleType) {
    CropScaleTypeCustom,
    CropScaleTypeOriginal,
    CropScaleType1To1,
    CropScaleType3To2,
    CropScaleType2To3,
    CropScaleType4To3,
    CropScaleType3To4,
    CropScaleType16To9,
    CropScaleType9To16,
};

@interface CropView : UIView

#pragma mark - 功能

/** 裁剪框的 frame */
@property (nonatomic, assign, readonly)CGRect cropFrame;

/** 裁剪框占据整个视图的位置比例（0，0，0，0）是左上角 （1，1，1，1）是右下角*/
@property (nonatomic, assign, readonly)CGRect cropFrameRatio;

/** 设置缩放的长宽比 */
@property (nonatomic, assign)CropScaleType scaleType;

/** 设置缩放的长宽比，以及是否进行动画 */
- (void)setScaleType:(CropScaleType)scaleType animated:(BOOL)animated;

/** 每次拖动裁剪框后的回调 */
@property (nonatomic, copy)void (^completionHandler) (void);

#pragma mark - 外观

/** 裁剪框边框粗细 */
@property (nonatomic, assign)CGFloat borderWidth;
/** 裁剪框边框颜色 */
@property (nonatomic, strong)UIColor *borderColor;
/** 遮罩层颜色 */
@property (nonatomic, strong)UIColor *maskColor;
/** 裁剪框最小边长 */
@property (nonatomic, assign)CGFloat minLenghOfSide;


@end
