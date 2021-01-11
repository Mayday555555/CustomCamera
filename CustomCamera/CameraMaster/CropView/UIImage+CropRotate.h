//
//  UIImage+CropRotate.h
//
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (TOCropRotate)
- (nonnull UIImage *)croppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle circularClip:(BOOL)circular;
- (UIImage *)croppedImageWithFrame:(CGRect)frame;
/** 将图片旋转degrees角度 */
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

/** 将图片旋转radians弧度 */
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;

/** 纠正图片的方向 */
- (UIImage *)fixOrientation;

@end

NS_ASSUME_NONNULL_END
