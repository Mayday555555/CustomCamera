//
//  CamareTopView.m
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import "CamareTopView.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define kScaleWidth(R) (R)*(SCREEN_WIDTH)/375.0
@interface CamareTopView()
@property (nonatomic,strong) UIButton * flashBtn;//闪光灯
@property (nonatomic,strong) UIButton * changeBackAndFrontBtn;//切换前置后置按钮
@end
@implementation CamareTopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.topViewHeight = frame.size.height;
        self.backgroundColor = [UIColor blackColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.flashBtn];
    [self addSubview:self.changeBackAndFrontBtn];
}

#pragma mark - Lazy init

- (UIButton *)flashBtn {
    if (!_flashBtn) {
        _flashBtn = [[UIButton alloc]init];
        [_flashBtn setImage:[self getPictureWithName:@"light_off@3x"] forState:UIControlStateNormal];
        [_flashBtn setImage:[self getPictureWithName:@"light_on@3x"] forState:UIControlStateSelected];
        [_flashBtn addTarget:self action:@selector(flashBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _flashBtn.frame = CGRectMake(20, self.topViewHeight - kScaleWidth(40), kScaleWidth(58), kScaleWidth(40));
    }
    return _flashBtn;
}

- (UIButton *)changeBackAndFrontBtn {
    if (!_changeBackAndFrontBtn) {
        _changeBackAndFrontBtn = [[UIButton alloc]init];
        [_changeBackAndFrontBtn setImage:[self getPictureWithName:@"ic_qh_sxt@3x"] forState:UIControlStateNormal];
        [_changeBackAndFrontBtn addTarget:self action:@selector(changeBackAndFrontBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _changeBackAndFrontBtn.frame = CGRectMake(SCREEN_WIDTH - kScaleWidth(58) - 20, self.topViewHeight - kScaleWidth(40), kScaleWidth(58), kScaleWidth(40));
    
    }
    return _changeBackAndFrontBtn;
}

#pragma mark - Setting
- (void)setDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    if (_deviceOrientation == deviceOrientation) {
        return;
    } else {
        _deviceOrientation = deviceOrientation;
    }
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        //顺时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.flashBtn.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        self.changeBackAndFrontBtn.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.flashBtn.imageView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.flashBtn.imageView.transform = transform;
        self.changeBackAndFrontBtn.imageView.transform = transform;
        [UIView commitAnimations];
    } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        //逆时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.flashBtn.imageView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        self.changeBackAndFrontBtn.imageView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        CGAffineTransform transform = self.flashBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.flashBtn.imageView.transform = transform;
        self.changeBackAndFrontBtn.imageView.transform = transform;
        [UIView commitAnimations];
    } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        //逆时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.flashBtn.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        self.changeBackAndFrontBtn.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.flashBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.flashBtn.imageView.transform = transform;
        self.changeBackAndFrontBtn.imageView.transform = transform;
        [UIView commitAnimations];
    }
}

- (void)setHideRightBtn:(BOOL)hideRightBtn {
    _hideRightBtn = hideRightBtn;
    self.changeBackAndFrontBtn.hidden = hideRightBtn;
}

#pragma mark - User Interaction

- (void)flashBtnClick:(UIButton *)btn {
    self.isLightOn = !self.isLightOn;
    self.flashBtn.selected = self.isLightOn;
    if ([self.delegate respondsToSelector:@selector(flashBtnClick:)]) {
        [self.delegate flashBtnClick:self.isLightOn];
    }
}

- (void)changeBackAndFrontBtnClick:(UIButton *)btn {
    self.isFrontCamera = !self.isFrontCamera;
    if ([self.delegate respondsToSelector:@selector(changeBackAndFrontBtnClick:)]) {
        [self.delegate changeBackAndFrontBtnClick:self.isFrontCamera];
    }
}

- (UIImage *)getPictureWithName:(NSString *)name{
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YSCrop" ofType:@"bundle"]];
    NSString *path   = [bundle pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

@end
