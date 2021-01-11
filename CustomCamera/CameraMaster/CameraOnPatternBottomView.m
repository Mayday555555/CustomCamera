//
//  CameraOnPatternBottomView.m
//  EagleCloud
//
//  Created by 陈铉泽 on 2020/12/18.
//  Copyright © 2020 YS. All rights reserved.
//

#import "CameraOnPatternBottomView.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define kScaleWidth(R) (R)*(SCREEN_WIDTH)/375.0
@interface CameraOnPatternBottomView()
@property (nonatomic,strong) UIButton * closeBtn;//关闭按钮
@property (nonatomic,strong) UIButton * centerBtn;//
@property (nonatomic,strong) UIButton * albumBtn;//相册按钮
@property (nonatomic,strong) UIButton * pauseBtn;//暂停视频按钮
@end
@implementation CameraOnPatternBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.bottomViewHeight = frame.size.height;
        self.backgroundColor = [UIColor blackColor];
        self.videoState = 1;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.closeBtn];
    [self addSubview:self.centerBtn];
    [self addSubview:self.albumBtn];
    [self addSubview:self.pauseBtn];
}

#pragma mark - Lazy init
- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [[UIButton alloc]init];
        [_closeBtn setImage:[self getPictureWithName:@"ic_photo_close@3x"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.frame = CGRectMake(30, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _closeBtn;
}

- (UIButton *)centerBtn {
    if (!_centerBtn) {
        _centerBtn = [[UIButton alloc]init];
        [_centerBtn setImage:[self getPictureWithName:@"ic_paishe@2x"] forState:UIControlStateNormal];
        
        [_centerBtn addTarget:self action:@selector(centerBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _centerBtn.frame = CGRectMake((SCREEN_WIDTH - kScaleWidth(58))/2, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _centerBtn;
}

- (UIButton *)pauseBtn {
    if (!_pauseBtn) {
        _pauseBtn = [[UIButton alloc]init];
        [_pauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [_pauseBtn addTarget:self action:@selector(pauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _pauseBtn.frame = CGRectMake((SCREEN_WIDTH - kScaleWidth(58))/2 + kScaleWidth(58) + 20, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _pauseBtn;
}

- (UIButton *)albumBtn {
    if (!_albumBtn) {
        _albumBtn = [[UIButton alloc]init];
        [_albumBtn setImage:[self getPictureWithName:@"ic_ys_takePictures_album@2x"] forState:UIControlStateNormal];
        [_albumBtn addTarget:self action:@selector(albumBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _albumBtn.frame = CGRectMake(SCREEN_WIDTH - kScaleWidth(58) - 30, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _albumBtn;
}



- (void)setVideoState:(NSInteger)videoState {
    if (videoState == 1) {
        [self.centerBtn setImage:[self getPictureWithName:@"ic_paishe@3x"] forState:UIControlStateNormal];
    } else if (videoState == 2) {
        [self.centerBtn setImage:[self getPictureWithName:@"ic_videostop@3x"] forState:UIControlStateNormal];
    } else {
//        [self.centerBtn setImage:[self getPictureWithName:@"ic_photo_sure"] forState:UIControlStateNormal];
    }
}

- (void)setCameraType:(NSInteger)cameraType {
    if (cameraType == 1) {
        [self.centerBtn setImage:[self getPictureWithName:@"ic_photo@3x"] forState:UIControlStateNormal];
        self.pauseBtn.hidden = YES;
    } else {
        [self.centerBtn setImage:[self getPictureWithName:@"ic_paishe@3x"] forState:UIControlStateNormal];
        self.pauseBtn.hidden = NO;
    }
}

- (void)setPause:(BOOL)isPause {
    if (isPause) {
        [self.pauseBtn setTitle:@"继续" forState:UIControlStateNormal];
    } else {
        [self.pauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
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
        self.albumBtn.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.albumBtn.imageView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.albumBtn.imageView.transform = transform;
        [UIView commitAnimations];
    } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        //逆时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.albumBtn.imageView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        CGAffineTransform transform = self.albumBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.albumBtn.imageView.transform = transform;
        [UIView commitAnimations];
    } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        //逆时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.albumBtn.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.albumBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.albumBtn.imageView.transform = transform;
        [UIView commitAnimations];
    }
}

#pragma mark - User Interaction
- (void)closeBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(onlyVideoCloseBtnClick)]) {
        [self.delegate onlyVideoCloseBtnClick];
    }
}

- (void)centerBtnClick:(UIButton *)btn {
//    if (self.cameraTyp == 2) {
//        if (self.videoState == 1) {
//            self.videoState = 2;
//        } else if (self.videoState == 2) {
//            self.videoState = 3;
//        }
//    }
    
    if ([self.delegate respondsToSelector:@selector(onlyVideoCenterBtnClick)]) {
        [self.delegate onlyVideoCenterBtnClick];
    }
}

- (void)albumBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(albumBtnClick)]) {
        [self.delegate albumBtnClick];
    }
}

- (void)pauseBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(pauseBtnClick)]) {
        [self.delegate pauseBtnClick];
    }
}

- (UIImage *)getPictureWithName:(NSString *)name{
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YSCrop" ofType:@"bundle"]];
    NSString *path   = [bundle pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}


@end
