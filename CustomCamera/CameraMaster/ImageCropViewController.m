//
//  ImageCropViewController.m
//  CYImageCrop
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import "ImageCropViewController.h"
#import "ImageCropToolView.h"
#import "CropView.h"
#import "UIImageView+Crop.h"
#import "UIImage+CropRotate.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
@interface ImageCropViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) ImageCropToolView *toolView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, assign) BOOL isImageVertical;
@property (nonatomic, assign) CGFloat topBgViewHeight;
@property (nonatomic, assign) CGFloat imageMaxHeight;
@property (nonatomic, assign) CGFloat imageMaxWidth;
@property (nonatomic, assign) BOOL    isIphoneX;
// 正在动画ing中
@property (nonatomic, assign) BOOL rotateAnimationInProgress;
@end

@implementation ImageCropViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isIphoneX = [self isIphoneXS];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    NSLog(@"ImageCropViewControllerDealloc");
}

//- (BOOL)prefersStatusBarHidden {
//    return true;
//}

/// 不支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    
    [self.view  addSubview:self.bgView];
    [self.bgView  addSubview:self.imageView];
    [self.bgView  addSubview:self.toolView];
    
    // frame
    self.topBgViewHeight = SCREEN_HEIGHT-102-(_isIphoneX?25:5);
    self.imageMaxHeight = self.topBgViewHeight-70;
    self.imageMaxWidth = SCREEN_WIDTH-15;
    self.imageView.image = self.originImage;
    self.isImageVertical = YES;
    CGSize imageSize = [self commonImageSizeWithImage:self.originImage];
//    CGSize imageSize = self.imageView.cy_contentFrame.size;
    // 调整图片宽高设置imageView
    self.imageView.frame = CGRectMake((SCREEN_WIDTH-imageSize.width)/2,(self.topBgViewHeight-imageSize.height)/2+28, imageSize.width, imageSize.height);
    
    
    // 设置缩放边长的最小值，默认为100
    self.imageView.cropView.minLenghOfSide = 80;
    // 设置裁剪框边框，默认为 2.0
    self.imageView.cropView.borderWidth = 0.5;
    self.imageView.cropView.borderColor = [UIColor colorWithWhite:1 alpha:0.4];
    // 设置遮罩层颜色，默认为 [UIColor colorWithWhite:0 alpha:0.5]
    self.imageView.cropView.maskColor = [UIColor colorWithWhite:0 alpha:0.6];
    // 设置每次拖拽后的回调，默认为空
    __weak typeof(self) weakSelf = self;
    [self.imageView setComplectionHandler:^{
        NSLog(@"实际裁剪区域: %@", NSStringFromCGRect(weakSelf.imageView.cropFrame));
        NSLog(@"比例裁剪区域: %@", NSStringFromCGRect(weakSelf.imageView.cropFrameRatio));
    }];
    [self.imageView showCropViewWithType:CropScaleTypeCustom];
    
    //开启和监听 设备旋转的通知（不开启的话，设备方向一直是UIInterfaceOrientationUnknown）
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleDeviceOrientationChange:)
                                         name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark  业务方法
/// 通过image设置ImageViewSize
- (CGSize)commonImageSizeWithImage:(UIImage *)image  {
    if (!image) {
        return CGSizeZero;
    }
    CGFloat imageHeight = image.size.height;
    CGFloat imageWidth = image.size.width;
    CGFloat whRatio = imageWidth/imageHeight;
    //默认垂直方向
    if (imageHeight>self.imageMaxHeight) {
        imageHeight = self.imageMaxHeight;
        imageWidth = imageHeight*whRatio;
    }
    if (imageWidth>self.imageMaxWidth) {
        imageWidth = self.imageMaxWidth;
        imageHeight = imageWidth/whRatio;
    }
    return CGSizeMake(imageWidth,imageHeight);
}

- (CGSize)commonImageSizeWithSize:(CGSize)size  {
    CGFloat imageHeight = size.height;
    CGFloat imageWidth = size.width;
    CGFloat whRatio = imageWidth/imageHeight;
    //默认垂直方向
    if (imageHeight>self.imageMaxHeight) {
        imageHeight = self.imageMaxHeight;
        imageWidth = imageHeight*whRatio;
    }
    if (imageWidth>self.imageMaxWidth) {
        imageWidth = self.imageMaxWidth;
        imageHeight = imageWidth/whRatio;
    }
    return CGSizeMake(imageWidth,imageHeight);
}

// 设备方向改变的处理
- (void)handleDeviceOrientationChange:(NSNotification *)notification{

    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        //屏幕直立
        if (self.toolView.deviceRatate) {
            self.toolView.deviceRatate = NO;
        }
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        if (!self.toolView.deviceRatate) {
            self.toolView.deviceRatate = YES;
        }
    }
}

- (BOOL)isIphoneXS
{
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        
        iPhoneXSeries = YES;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    
    return iPhoneXSeries;
}

#pragma mark -imageView
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _bgView.backgroundColor = self.backgroundColor?:UIColor.blackColor;
    }
    return _bgView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (ImageCropToolView *)toolView {
    if (!_toolView) {
        _toolView = [[ImageCropToolView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-102-(_isIphoneX?25:5),SCREEN_WIDTH, 102)];
        __weak typeof(self) weakSelf = self;
        _toolView.cancelBlock = ^{
            [weakSelf dismissViewControllerAnimated:!weakSelf.needNoAnimationDismiss completion:nil];
        };
        _toolView.confirmBlock = ^{
            [weakSelf dismissViewControllerAnimated:!weakSelf.needNoAnimationDismiss completion:nil];
            if (weakSelf.imageCropBlock) {
                UIImage *img = weakSelf.imageView.image;
                CGFloat imgH = img.size.height;
                CGFloat imgW = img.size.width;
                CGRect cropFrame = CGRectMake(imgW*weakSelf.imageView.cropFrameRatio.origin.x, imgH*weakSelf.imageView.cropFrameRatio.origin.y, imgW*weakSelf.imageView.cropFrameRatio.size.width, imgH*weakSelf.imageView.cropFrameRatio.size.height);
                UIImage *image = [weakSelf.imageView.image croppedImageWithFrame:cropFrame];
                
                NSLog(@"------当前旋转度数\n%@\n",@(weakSelf.angle));
                if (weakSelf.angle != 0) {
                    UIImage *ratateImage  = [image imageRotatedByDegrees:[@(weakSelf.angle) floatValue]];
                    weakSelf.imageCropBlock(ratateImage);
                }else {
                    weakSelf.imageCropBlock(image);
                }
            }
        };
        _toolView.ratateBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.rotateAnimationInProgress) return;
                
//                UIImage *lastImage = weakSelf.imageView.image;
                CGSize lastImageSize = weakSelf.imageView.frame.size;
                //  每次旋转90度
                weakSelf.isImageVertical = !weakSelf.isImageVertical;
//                //计算出新角度，并在超过360度时调整
                NSInteger newAngle = weakSelf.angle;
                // 顺时针旋转 newAngle + 90 逆时针 newAngle - 90
                newAngle = newAngle + 90;
                if (newAngle <= -360 || newAngle >= 360) {
                    newAngle = 0;
                }
                weakSelf.angle = newAngle;
                
                // 设置旋转后的图片尺寸
                CGSize imageSize = [weakSelf commonImageSizeWithSize:weakSelf.isImageVertical?weakSelf.originImage.size:CGSizeMake(weakSelf.originImage.size.height, weakSelf.originImage.size.width)];
                // 隐藏裁剪框
                [weakSelf.imageView hideCropViewWithAnimated:NO];
                
                weakSelf.rotateAnimationInProgress = YES;
                [UIView animateWithDuration:0.15 animations:^{
                    //缩放
                    if (weakSelf.isImageVertical) {
                        CGFloat scale2 = imageSize.width/lastImageSize.height;
                        NSLog(@"----当前scale---%@,%@",@(scale2),@(scale2));
                        CGAffineTransform transformScale = CGAffineTransformScale(weakSelf.imageView.transform, scale2,scale2);
                        weakSelf.imageView.transform = transformScale;
                    }else {
                        CGFloat scale1 = imageSize.height/lastImageSize.width;
                        NSLog(@"----当前scale---%@,%@",@(scale1),@(scale1));
                        CGAffineTransform transformScale = CGAffineTransformScale(weakSelf.imageView.transform, scale1,scale1);
                        weakSelf.imageView.transform = transformScale;
                    }
                    
//                    weakSelf.imageView.frame = CGRectMake((SCREEN_WIDTH-imageSize.width)/2,(weakSelf.topBgViewHeight-imageSize.height)/2+28, imageSize.width, imageSize.height);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.15 animations:^{
                        CGAffineTransform rotation = CGAffineTransformRotate(weakSelf.imageView.transform, (M_PI * (90) / 180.0));
                        weakSelf.imageView.transform = rotation;
                    } completion:^(BOOL finished) {
                        weakSelf.rotateAnimationInProgress = NO;
                    }];
                    [weakSelf.imageView  updateLayoutCropView];
                    [weakSelf.imageView showCropViewWithType:CropScaleTypeCustom];
                }];
            });
        };
    }
    return _toolView;
}
@end
