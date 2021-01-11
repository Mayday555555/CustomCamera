//
//  CameraBottomView.m
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import "CameraBottomView.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define kScaleWidth(R) (R)*(SCREEN_WIDTH)/375.0
@interface CameraBottomView()
@property (nonatomic,strong) UIButton * closeBtn;//关闭按钮
@property (nonatomic,strong) UIButton * centerBtn;//闪光灯
@property (nonatomic,strong) UIButton * changeCameraTypeBtn;//切换视频拍照按钮
@property (nonatomic,strong) UIButton * playBtn;//播放视频
@property (nonatomic,strong) UIImageView * playImage;//播放视频图片

@end
@implementation CameraBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.bottomViewHeight = frame.size.height;
        self.backgroundColor = [UIColor blackColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.closeBtn];
    [self addSubview:self.centerBtn];
    [self addSubview:self.changeCameraTypeBtn];
    [self addSubview:self.playBtn];
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
        [_centerBtn setImage:[self getPictureWithName:@"ic_photo@3x"] forState:UIControlStateNormal];
        
        [_centerBtn addTarget:self action:@selector(centerBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _centerBtn.frame = CGRectMake((SCREEN_WIDTH - kScaleWidth(58))/2, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _centerBtn;
}

- (UIButton *)changeCameraTypeBtn {
    if (!_changeCameraTypeBtn) {
        _changeCameraTypeBtn = [[UIButton alloc]init];
        [_changeCameraTypeBtn setImage:[self getPictureWithName:@"ic_paishe_qh@3x"] forState:UIControlStateNormal];
        [_changeCameraTypeBtn addTarget:self action:@selector(changeCameraTypeBtnBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _changeCameraTypeBtn.frame = CGRectMake(SCREEN_WIDTH - kScaleWidth(58) - 30, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
    }
    return _changeCameraTypeBtn;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [[UIButton alloc]init];
        [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.frame = CGRectMake(SCREEN_WIDTH - kScaleWidth(58) - 30, (self.bottomViewHeight - kScaleWidth(58))/2, kScaleWidth(58), kScaleWidth(58));
        self.playImage = [[UIImageView alloc]initWithFrame:CGRectMake(kScaleWidth((58 - 25)/2), kScaleWidth((58 - 25)/2), kScaleWidth(25), kScaleWidth(25))];
        [_playBtn addSubview:self.playImage];
        _playBtn.hidden = YES;
    }
    return _playBtn;
}

- (void)setVideoState:(NSInteger)videoState {
    if (videoState == 1) {
        self.playBtn.hidden = YES;
        self.changeCameraTypeBtn.hidden = NO;
        [self.centerBtn setImage:[self getPictureWithName:@"ic_paishe@3x"] forState:UIControlStateNormal];
    } else if (videoState == 2) {
        self.playBtn.hidden = YES;
        self.changeCameraTypeBtn.hidden = NO;
        [self.centerBtn setImage:[self getPictureWithName:@"ic_videostop@3x"] forState:UIControlStateNormal];
    } else {
        self.playBtn.hidden = NO;
        self.changeCameraTypeBtn.hidden = YES;
        [self.centerBtn setImage:[self getPictureWithName:@"ic_photo_sure@3x"] forState:UIControlStateNormal];
    }
}

- (void)setIsPlaying:(BOOL)isPlaying {
    if (isPlaying) {
        self.playImage.image = [self getPictureWithName:@"ic_pause@2x"];
    } else {
        self.playImage.image = [self getPictureWithName:@"ic_play@2x"];
    }
}

- (void)setCameraType:(NSInteger)cameraType {
    if (cameraType == 1) {
        //切换成拍照模式
        [self.changeCameraTypeBtn setImage:[self getPictureWithName:@"ic_paishe_qh@3x"] forState:UIControlStateNormal];
        [self.centerBtn setImage:[self getPictureWithName:@"ic_photo@3x"] forState:UIControlStateNormal];
    } else {
        //切换成视频模式
        [self.changeCameraTypeBtn setImage:[self getPictureWithName:@"ic_xiangji_qh@3x"] forState:UIControlStateNormal];
        [self.centerBtn setImage:[self getPictureWithName:@"ic_paishe@3x"] forState:UIControlStateNormal];
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
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.centerBtn.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        self.changeCameraTypeBtn.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        self.playImage.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.centerBtn.imageView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.centerBtn.imageView.transform = transform;
        self.changeCameraTypeBtn.imageView.transform = transform;
        self.playImage.transform = transform;
        [UIView commitAnimations];
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.centerBtn.imageView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        self.changeCameraTypeBtn.imageView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        self.playImage.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        CGAffineTransform transform = self.centerBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.centerBtn.imageView.transform = transform;
        self.changeCameraTypeBtn.imageView.transform = transform;
        self.playImage.transform = transform;
        [UIView commitAnimations];
    } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.centerBtn.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        self.changeCameraTypeBtn.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        self.playImage.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.centerBtn.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.centerBtn.imageView.transform = transform;
        self.changeCameraTypeBtn.imageView.transform = transform;
        self.playImage.transform = transform;
        [UIView commitAnimations];
    }
}

#pragma mark - User Interaction
- (void)closeBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(closeBtnClick)]) {
        [self.delegate closeBtnClick];
    }
}

- (void)centerBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(centerBtnClick)]) {
        [self.delegate centerBtnClick];
    }
}

- (void)changeCameraTypeBtnBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(changeCameraTypeBtnClick)]) {
        [self.delegate changeCameraTypeBtnClick];
    }
}

- (void)playBtnClick:(UIButton *)btn {
    if ([self.delegate respondsToSelector:@selector(playBtnClick)]) {
        [self.delegate playBtnClick];
    }
}

- (UIImage *)getPictureWithName:(NSString *)name{
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YSCrop" ofType:@"bundle"]];
    NSString *path   = [bundle pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

@end
