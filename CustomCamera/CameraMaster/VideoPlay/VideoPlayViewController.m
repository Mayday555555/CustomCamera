//
//  VideoPlayViewController.m
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import "VideoPlayViewController.h"
#import "CustomVideoPlayView.h"
#import "CameraBottomView.h"
#import "DeviceOrientation.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define kScaleWidth(R) (R)*(SCREEN_WIDTH)/375.0
@interface VideoPlayViewController ()<CameraBottomViewDelegate,CustomVideoPlayViewDelegate,DeviceOrientationDelegate>
@property (nonatomic, strong)CustomVideoPlayView *videoPlayView;
@property (nonatomic, strong)CameraBottomView *bottomView;
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
@property (nonatomic, strong)DeviceOrientation *orientationMonitor;
@property (nonatomic, assign) BOOL isIphoneX;//是否是iphonex；
@property (nonatomic, assign)CGFloat bottomViewHeight;//底栏高度
@property (nonatomic, assign)CGFloat bottomViewBottom;//底栏和屏幕底部距离
@property (nonatomic, assign)CGFloat topViewHeight;//顶栏高度

@property (nonatomic, assign)BOOL isPlaying;
@end

@implementation VideoPlayViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isIphoneX = [self isIphoneXS];
        _topViewHeight = (_isIphoneX?69:49);
        _bottomViewBottom = (_isIphoneX?25:5);
        _bottomViewHeight = 102;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return true;
}

/// 不支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
//    [self addOrientationNotification];
//    [self handleDeviceOrientationChange];
    self.orientationMonitor = [[DeviceOrientation alloc]initWithDelegate:self];
    [self.orientationMonitor startMonitor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    self.videoPlayView = [[CustomVideoPlayView alloc]initWithFrame:CGRectMake(0, self.topViewHeight, SCREEN_WIDTH, SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom) withShowInView:self.view url:self.videoUrl];
    self.videoPlayView.delegate = self;
    self.bottomView = [[CameraBottomView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-self.bottomViewHeight-self.bottomViewBottom,SCREEN_WIDTH, self.bottomViewHeight)];
    [self.bottomView setCameraType:2];
    [self.bottomView setVideoState:3];
    self.bottomView.isPlaying = YES;
    self.bottomView.delegate = self;
    [self.view addSubview:self.bottomView];
}

- (void)playbackFinished {
    self.bottomView.isPlaying = NO;
}

- (void)closeBtnClick {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)centerBtnClick {
    [self dismissViewControllerAnimated:NO completion:nil];
    if ([self.delegate respondsToSelector:@selector(didSelectVideo)]) {
        [self.delegate didSelectVideo];
    }
}

- (void)playBtnClick {
    if (!self.isPlaying) {
        [self.videoPlayView play];
    } else {
        [self.videoPlayView stopPlayer];
    }
    self.isPlaying = !self.isPlaying;
    [self.bottomView setIsPlaying:self.isPlaying];
}

#pragma mark - 屏幕旋转处理
- (void)addOrientationNotification {
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleDeviceOrientationChange)
                                                name:UIDeviceOrientationDidChangeNotification object:nil];
}

// 设备方向改变的处理
- (void)handleDeviceOrientationChange{
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        //屏幕直立
        NSLog(@"UIDeviceOrientationPortrait");
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        NSLog(@"UIDeviceOrientationLandscapeRight");
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        NSLog(@"UIDeviceOrientationLandscapeLeft");
    }
    
    if (self.deviceOrientation != deviceOrientation) {
        [self setDeviceRatate:deviceOrientation animate:YES];
    }
}

- (void)setDeviceRatate:(UIDeviceOrientation)deviceOrientation animate:(BOOL)animate {
    float time = 0;
    if (animate) {
        time = 0.2;
    }
    
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        self.deviceOrientation = deviceOrientation;
        //屏幕直立
        self.bottomView.deviceOrientation = deviceOrientation;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.videoPlayView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.videoPlayView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.videoPlayView.transform = transform;
        [UIView commitAnimations];
        self.videoPlayView.frame = CGRectMake(0, self.topViewHeight, SCREEN_WIDTH, SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom);
        [self.videoPlayView resetUI:self.videoPlayView.bounds];
        if (self.lanscapeRecordRuning) {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        } else {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        self.deviceOrientation = deviceOrientation;
        self.bottomView.deviceOrientation = deviceOrientation;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.videoPlayView.frame = CGRectMake(-((SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom - SCREEN_WIDTH)/2), self.topViewHeight + ((SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom - SCREEN_WIDTH) / 2), SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom, SCREEN_WIDTH);
        [self.videoPlayView resetUI:self.videoPlayView.bounds];
        self.videoPlayView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        CGAffineTransform transform = self.videoPlayView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.videoPlayView.transform = transform;
        [UIView commitAnimations];
        if (self.lanscapeRecordRuning) {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        } else {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        }
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        self.deviceOrientation = deviceOrientation;
        self.bottomView.deviceOrientation = deviceOrientation;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.videoPlayView.frame = CGRectMake(-((SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom - SCREEN_WIDTH)/2), self.topViewHeight + ((SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom - SCREEN_WIDTH) / 2), SCREEN_HEIGHT - self.topViewHeight -self.bottomViewHeight-self.bottomViewBottom, SCREEN_WIDTH);
        [self.videoPlayView resetUI:self.videoPlayView.bounds];
        self.videoPlayView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.videoPlayView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.videoPlayView.transform = transform;
        [UIView commitAnimations];
        if (self.lanscapeRecordRuning) {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        } else {
            self.videoPlayView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        }
    }
}

#pragma mark - DeviceOrientationDelegate
- (void)directionChange:(TgDirection)direction {
    UIDeviceOrientation deviceOrientation;
    switch (direction) {
        case TgDirectionPortrait:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
        case TgDirectionDown:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
        case TgDirectionRight:
            deviceOrientation = UIDeviceOrientationLandscapeRight;
            break;
        case TgDirectionleft:
            deviceOrientation = UIDeviceOrientationLandscapeLeft;
            break;
        default:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
    }
    if (self.deviceOrientation != deviceOrientation) {
        [self setDeviceRatate:deviceOrientation animate:YES];
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

@end
