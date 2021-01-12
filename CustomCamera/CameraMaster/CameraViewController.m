//
//  CameraViewController.m
//  TomDemo
//  拍照&摄像公共控制器
//  Created by tom on 2020/12/17.
//

#import "CameraViewController.h"
#import <Photos/Photos.h>
#import "CamareTopView.h"
#import "CameraBottomView.h"
#import "CameraOnPatternBottomView.h"
#import "VideoPlayViewController.h"
#import "ImageCropViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"
#import "DeviceOrientation.h"
@interface CameraViewController ()<CAAnimationDelegate,CamareTopViewDelegate,CameraBottomViewDelegate,CameraOnPatternBottomViewDelegate,VideoPlayViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CustomCameraManagerDelegate,DeviceOrientationDelegate>
@property (nonatomic, strong)CustomCameraManager            *cameraManager;
@property (nonatomic, strong)CamareTopView *topView;//顶栏（单录像单拍照模式没有切换前后摄像头）
@property (nonatomic, assign)CGFloat topViewHeight;//顶栏高度
@property (nonatomic, strong)CameraBottomView *bottomView;//底栏（可切换录像拍照）
@property (nonatomic, strong)CameraOnPatternBottomView *onePatternBottomView;//底栏（单录像单拍照，可从相册选择视频）
@property (nonatomic, assign)CGFloat bottomViewHeight;//底栏高度
@property (nonatomic, assign)CGFloat bottomViewBottom;//底栏和屏幕底部距离
@property (nonatomic, strong) UIView                        *timeView;//录像时间显示背景
@property (nonatomic, strong) UILabel                       *timeLabel;//录像时间显示
/*UI*/
@property (nonatomic, strong) UIImageView                   *pictureShowIV;//照片展示
@property (nonatomic, strong) UIVisualEffectView            *maskView;
@property (nonatomic, strong) UIView                        *gestureView;//用于添加手势的view
@property (nonatomic, strong) UIImage                       *image;//拍照获得的照片

@property (nonatomic, strong) UIPinchGestureRecognizer      *pinchGesture;//缩放手势
@property (nonatomic, assign) CGFloat                       initialPinchZoom;
@property (nonatomic, strong) NSURL                         *videoUrl;
@property (nonatomic, assign) BOOL                          isFirstComeIn;
@property (nonatomic, assign) CGFloat                       screenWidth;
@property (nonatomic, assign) CGFloat                       screenHeight;
@property (nonatomic, assign) BOOL                          isIphoneX;
@property (nonatomic, assign) BOOL                          lanscapeRecordRuning;//记录开始录制时的屏幕方向

@property (nonatomic, assign)NSInteger cameraType;//1拍照 2录视频


@property (strong, nonatomic) UIImagePickerController *moviePicker;//视频选择器
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
@property (nonatomic, strong)DeviceOrientation *orientationMonitor;
@end

@implementation CameraViewController

#pragma mark - Life Cycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"CameraViewController Dealloc");
}

- (instancetype)initWithCameraMode:(CameraMode)cameraMode {
    self = [super init];
    if (self) {
        _isIphoneX = [self isIphoneXS];
        _topViewHeight = (_isIphoneX?69:49);
        _bottomViewBottom = (_isIphoneX?25:5);
        _bottomViewHeight = 102;
        _cameraMode = cameraMode;
        _videoQuality = AVCaptureSessionPreset1920x1080;
        _maxVideoDuration = 300;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        //初始化
        self.cameraType = 1;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    
    
    _isFirstComeIn = YES;
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    _gestureView = [[UIView alloc] init];
    _gestureView.clipsToBounds = YES;
    [self.view addSubview:_gestureView];
    
    if ([self checkCameraPermission]) {
        self.cameraManager = [[CustomCameraManager alloc]initWithCameraMode:self.cameraMode];
        self.cameraManager.delegate = self;
        [self addSubViews];
    }
    
    self.deviceOrientation = UIDeviceOrientationPortrait;
    self.orientationMonitor = [[DeviceOrientation alloc]initWithDelegate:self];
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    _screenWidth = self.view.bounds.size.width;
    _screenHeight = self.view.bounds.size.height;
    _maskView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    
    _gestureView.frame = CGRectMake(0, self.topViewHeight, _screenWidth, _screenHeight-_topViewHeight-_bottomViewHeight-_bottomViewBottom);
    
    [self.cameraManager setPreviewLayerFrame:self.gestureView.bounds];
    _pictureShowIV.frame = _gestureView.frame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
//    [self addOrientationNotification];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self.cameraManager startRunningSession:YES];
//    [self handleDeviceOrientationChange];
    [self.orientationMonitor startMonitor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_isFirstComeIn) {
        if ([self checkCameraPermission]) {
            
        }else{
            __weak typeof (self) weakSelf = self;
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"提示" message:@"请到【设置】->【隐私】->【相机】中打开相机权限" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
                [weakSelf closeButtonClickAnimate:YES];
            }];
            
            UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"去设置" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:^(BOOL success) {
                        
                    }];
                }
                
                [weakSelf closeButtonClickAnimate:YES];
            }];
            
            [alertC addAction:cancleAction];
            [alertC addAction:confirmAction];
            
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
    
    _isFirstComeIn = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self reset];
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self.orientationMonitor stop];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self reset];
    [self clearPicture];
    
    [self.cameraManager startRunningSession:NO];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

/// 不支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willResignActiveNotification {
    [self reset];
    
    [self.cameraManager startRunningSession:NO];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 1.0;
    }];
}


- (void)didBecomeActiveNotification {
    [self.cameraManager startRunningSession:YES];
    [UIView animateWithDuration:0.25 animations:^{
        self.maskView.alpha = 0;
    }];
}

#pragma mark - UI设置
//UI
- (void)addSubViews {
    _maskView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _maskView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    _maskView.alpha = 0;
    [self.view addSubview:_maskView];
    
    _pictureShowIV = [[UIImageView alloc] init];
    _pictureShowIV.contentMode = UIViewContentModeScaleAspectFill;
    _pictureShowIV.userInteractionEnabled = YES;
    _pictureShowIV.hidden = YES;
    [self.view addSubview:_pictureShowIV];
    
    
    
    //缩放手势
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [_gestureView addGestureRecognizer:_pinchGesture];
    
    [self.view addSubview:self.topView];
    if (self.cameraMode == CameraModePictureAndVideo) {
        //可切换拍照和视频，右边按钮是切换按钮
        [self.view addSubview:self.bottomView];
    } else {
        //单视频模式，右边按钮是相册按钮，点击从相册选择视频
        [self.view addSubview:self.onePatternBottomView];
    }
    
    self.timeView.frame = CGRectMake((_screenWidth - 290) / 2, 30 + self.topView.topViewHeight, 290, 36);
    [self.view addSubview:self.timeView];
    
    [self.cameraManager addPreviewLayerToView:self.gestureView];
}

- (void)reset {
    _pinchGesture.enabled = YES;
    _timeLabel.text = @"00:00";
    _timeView.alpha = 0;
    
    [self.cameraManager resetData];
}

- (void)clearPicture {
    _pictureShowIV.image = nil;
    _pictureShowIV.hidden = YES;
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
        self.cameraManager.deviceOrientation = deviceOrientation;
        //屏幕直立
        self.topView.deviceOrientation = deviceOrientation;
        if (self.cameraMode == CameraModePictureAndVideo) {
            self.bottomView.deviceOrientation = deviceOrientation;
        } else {
            self.onePatternBottomView.deviceOrientation = deviceOrientation;
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.timeView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.timeView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.timeView.transform = transform;
        [UIView commitAnimations];
        self.timeView.frame = CGRectMake((_screenWidth - 290) / 2, 30 + self.topView.topViewHeight, 290, 36);
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
        self.deviceOrientation = deviceOrientation;
        self.cameraManager.deviceOrientation = deviceOrientation;
        self.topView.deviceOrientation = deviceOrientation;
        if (self.cameraMode == CameraModePictureAndVideo) {
            self.bottomView.deviceOrientation = deviceOrientation;
        } else {
            self.onePatternBottomView.deviceOrientation = deviceOrientation;
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.timeView.frame = CGRectMake(- (290 / 2 - 30),(_screenHeight - self.topView.topViewHeight - self.bottomView.bottomViewHeight) / 2 - 36 / 2 + self.topView.topViewHeight, 290, 36);
        self.timeView.transform = CGAffineTransformMakeRotation(-90 *M_PI / 180.0);
        CGAffineTransform transform = self.timeView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.timeView.transform = transform;
        [UIView commitAnimations];
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
        self.deviceOrientation = deviceOrientation;
        self.cameraManager.deviceOrientation = deviceOrientation;
        self.topView.deviceOrientation = deviceOrientation;
        if (self.cameraMode == CameraModePictureAndVideo) {
            self.bottomView.deviceOrientation = deviceOrientation;
        } else {
            self.onePatternBottomView.deviceOrientation = deviceOrientation;
        }
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0]; //动画时长));
        self.timeView.frame = CGRectMake(_screenWidth - 30 - 290 / 2,(_screenHeight - self.topView.topViewHeight - self.bottomView.bottomViewHeight) / 2 - 36 / 2 + self.topView.topViewHeight, 290, 36);
        self.timeView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.timeView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.timeView.transform = transform;
        [UIView commitAnimations];
    }
}

#pragma mark - DeviceOrientationDelegate
- (void)directionChange:(TgDirection)direction {
    UIDeviceOrientation deviceOrientation;
    switch (direction) {
        case TgDirectionPortrait:
            deviceOrientation = UIDeviceOrientationPortrait;
            NSLog(@"UIDeviceOrientationPortrait");
            break;
        case TgDirectionDown:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
        case TgDirectionRight:
            deviceOrientation = UIDeviceOrientationLandscapeRight;
            NSLog(@"UIDeviceOrientationLandscapeRight");
            break;
        case TgDirectionleft:
            deviceOrientation = UIDeviceOrientationLandscapeLeft;
            NSLog(@"UIDeviceOrientationLandscapeLeft");
            break;
        default:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
    }
    if (self.deviceOrientation != deviceOrientation) {
        [self setDeviceRatate:deviceOrientation animate:YES];
    }
}

#pragma mark - 视频保存成功
- (void)saveVideoToAlbum:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    //    [self.view hideHUD];
    NSLog(@"保存视频成功");
}

#pragma mark - User Interaction
#pragma mark - CamareTopViewDelegate
- (void)flashBtnClick:(BOOL)isLightOn {
    if (self.cameraMode == CameraModePictureAndVideo) {
        //可切换拍照和视频
        if (self.cameraType == 1) {
            if (isLightOn) {
                [self.cameraManager setLightOnWithFlashMode:AVCaptureFlashModeOn torchMode:-1];
            } else {
                [self.cameraManager setLightOnWithFlashMode:AVCaptureFlashModeOff torchMode:-1];
            }
        } else {
            if (isLightOn) {
                [self.cameraManager setLightOnWithFlashMode:-1 torchMode:AVCaptureTorchModeOn];
            } else {
                [self.cameraManager setLightOnWithFlashMode:-1 torchMode:AVCaptureTorchModeOff];
            }
        }
    } else if (self.cameraMode == CameraModeVideo) {
        //单视频
        if (isLightOn) {
            [self.cameraManager setLightOnWithFlashMode:-1 torchMode:AVCaptureTorchModeOn];
        } else {
            [self.cameraManager setLightOnWithFlashMode:-1 torchMode:AVCaptureTorchModeOff];
        }
    } else {
        //单拍照
        if (isLightOn) {
            [self.cameraManager setLightOnWithFlashMode:AVCaptureFlashModeOn torchMode:-1];
        } else {
            [self.cameraManager setLightOnWithFlashMode:AVCaptureFlashModeOff torchMode:-1];
        }
    }
}

- (void)changeBackAndFrontBtnClick:(BOOL)isFrontCamera {
    if (self.cameraManager.videoState == 2 &&  self.cameraMode == CameraModePictureAndVideo) {
        return;
    }
    [self.cameraManager changeFrontAndBackCamera];
}


#pragma mark - CameraBottomViewDelegate
/// 关闭按钮点击
- (void)closeBtnClick {
    if (self.cameraManager.videoState == 2) {
        return;
    }
    [self closeButtonClickAnimate:YES];
}

- (void)closeButtonClickAnimate:(BOOL)animate {
    if (self.presentingViewController) {
        if (self.navigationController) {
            if (self.navigationController.viewControllers.count > 1) {
                [self.navigationController popViewControllerAnimated:animate];
            }else{
                [self dismissViewControllerAnimated:animate completion:nil];
            }
        }else{
            [self dismissViewControllerAnimated:animate completion:nil];
        }
    }else{
        [self.navigationController popViewControllerAnimated:animate];
    }
}


- (void)centerBtnClick {
    if (self.cameraType == 1) {
        if ([self.cameraManager takePicture]) {
            _pictureShowIV.hidden = NO;
            _pinchGesture.enabled = NO;
        } else {
            _pictureShowIV.hidden = YES;
            _pinchGesture.enabled = YES;
        }
    } else {
        if (self.cameraManager.videoState == 1) {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            self.timeView.hidden = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.timeView.alpha = 1.0;
            }];
            
            [self.cameraManager startVideoWrite];
            
            
            
            [self.bottomView setVideoState:self.cameraManager.videoState];
        } else if (self.cameraManager.videoState == 2) {
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.timeView.alpha = 0;
            } completion:^(BOOL finished) {
                self.timeLabel.text = @"00:00";
            }];
            
            if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
                self.lanscapeRecordRuning = YES;
            }else {
                self.lanscapeRecordRuning = NO;
            }
            
            [self.cameraManager stopVideoWrite];
        }
    }
}

- (void)changeCameraTypeBtnClick {
    if (self.cameraManager.videoState == 2) {
        return;
    }
    if (self.cameraType == 1) {
        //切换成视频模式
        self.cameraType = 2;
    } else {
        //切换成拍照模式
        self.cameraType = 1;
    }
    [self.bottomView setCameraType:self.cameraType];
}

#pragma mark - CameraOnPatternBottomViewDelegate
- (void)onlyVideoCloseBtnClick {
    if (self.cameraManager.videoState == 2) {
        return;
    }
    [self closeButtonClickAnimate:YES];
}
- (void)onlyVideoCenterBtnClick {
    if (self.cameraMode == CameraModePicture) {
        if ([self.cameraManager takePicture]) {
            _pictureShowIV.hidden = NO;
            _pinchGesture.enabled = NO;
        } else {
            _pictureShowIV.hidden = YES;
            _pinchGesture.enabled = YES;
        }
    } else {
        if (self.cameraManager.videoState == 1) {
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            self.timeView.hidden = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.timeView.alpha = 1.0;
            }];
            
            [self.cameraManager startVideoWrite];
            
            [self.onePatternBottomView setVideoState:self.cameraManager.videoState];
        } else if (self.cameraManager.videoState == 2) {
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [UIView animateWithDuration:0.25 animations:^{
                self.timeView.alpha = 0;
            } completion:^(BOOL finished) {
                self.timeLabel.text = @"00:00";
            }];
            
            if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
                self.lanscapeRecordRuning = YES;
            }else {
                self.lanscapeRecordRuning = NO;
            }
            
            [self.cameraManager stopVideoWrite];
        }
    }
}

- (void)albumBtnClick {
    if (self.cameraManager.videoState == 2) {
        return;
    }
    [self presentViewController:self.moviePicker animated:YES completion:nil];
}

- (void)pauseBtnClick {
    [self.cameraManager pauseAndResumeVideoWrite];
    [self.onePatternBottomView setPause:self.cameraManager.isPause];
}

#pragma mark - VideoPlayViewControllerDelegate
- (void)didSelectVideo {
    if (self.dataBlock) {
        NSData *data = [NSData dataWithContentsOfURL:self.videoUrl];
        if (data) {
            self.dataBlock(nil,data);
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [self closeBtnClick];
}

#pragma mark - CustomCameraManagerDelegate
- (void)finishVideoWrite:(BOOL)success url:(NSURL *)url isLandscapeRecord:(BOOL)isLandscapeRecord{
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoUrl = url;
            VideoPlayViewController *vc = [[VideoPlayViewController alloc]init];
            vc.videoUrl = self.videoUrl;
            vc.lanscapeRecordRuning = isLandscapeRecord;
            vc.delegate = self;
            [self presentViewController:vc animated:NO completion:nil];
            NSLog(@"hasPresent");
            if (self.cameraMode == CameraModeVideo) {
                self.cameraManager.videoState = 1;
                [self.onePatternBottomView setVideoState:self.cameraManager.videoState];
            } else {
                self.cameraManager.videoState = 1;
                [self.bottomView setVideoState:self.cameraManager.videoState];
            }
        });
    }
    
}

- (void)refreshTime:(NSString *)timeStr {
    self.timeLabel.text = timeStr;
}

- (void)getPictureData:(NSData *)imageData {
    if (imageData) {
        ImageCropViewController *cropVC = [[ImageCropViewController alloc] init];
        cropVC.originImage = [UIImage imageWithData:imageData];
        cropVC.needNoAnimationDismiss = YES;
        cropVC.imageCropBlock = ^(UIImage * _Nonnull image) {
            //得到裁剪图片返回
            if (self.dataBlock) {
                self.dataBlock(UIImagePNGRepresentation(image), nil);
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        };
        [self presentViewController:cropVC animated:NO completion:nil];
    }else{
        _pictureShowIV.hidden = YES;
        _pinchGesture.enabled = YES;
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeMovie]) {
        //获取视频的名称
        NSString * videoPath=[NSString stringWithFormat:@"%@",[info objectForKey:UIImagePickerControllerMediaURL]];
        
        
        //如果视频是mov格式的则转为MP4的
        if (![videoPath hasSuffix:@"MP4"]  && ![videoPath hasSuffix:@"mp4"]) {
            NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
            __weak typeof(self) weakSelf = self;
            //转换成mp4格式
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            });
            //转成mp4
            [self.cameraManager changeMovToMp4:videoUrl dataBlock:^(NSURL * _Nonnull url) {
                [weakSelf.cameraManager movieToImageWithUrl:url handler:^(UIImage * _Nonnull movieImage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [weakSelf.moviePicker dismissViewControllerAnimated:YES completion:nil];
                        weakSelf.videoUrl = url;
                        VideoPlayViewController *vc = [[VideoPlayViewController alloc]init];
                        vc.videoUrl = weakSelf.videoUrl;
                        if (movieImage.size.width > movieImage.size.height) {
                            vc.lanscapeRecordRuning = YES;
                        } else {
                            vc.lanscapeRecordRuning = NO;
                        }
                        vc.delegate = weakSelf;
                        [weakSelf presentViewController:vc animated:NO completion:nil];
                        weakSelf.onePatternBottomView.videoState = 1;
                    });
                }];
            }];
            NSLog(@"filesize====%llu",[[[NSFileManager defaultManager] attributesOfItemAtPath:videoPath error:nil] fileSize]);
        } else {
            NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            });
            __weak typeof(self) weakSelf = self;
            [self.cameraManager movieToImageWithUrl:videoUrl handler:^(UIImage * _Nonnull movieImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [weakSelf.moviePicker dismissViewControllerAnimated:YES completion:nil];
                    weakSelf.videoUrl = videoUrl;
                    VideoPlayViewController *vc = [[VideoPlayViewController alloc]init];
                    vc.videoUrl = weakSelf.videoUrl;
                    if (movieImage.size.width > movieImage.size.height) {
                        vc.lanscapeRecordRuning = YES;
                    } else {
                        vc.lanscapeRecordRuning = NO;
                    }
                    vc.delegate = weakSelf;
                    [weakSelf presentViewController:vc animated:NO completion:nil];
                    weakSelf.onePatternBottomView.videoState = 1;
                });
            }];
        }
    } else {
        NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
        //当选择的类型是图片
        if ([type isEqualToString:@"public.image"])
        {
            UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
            if (photo) {
                [picker dismissViewControllerAnimated:YES completion:nil];
                // 跳转到裁剪页面
                ImageCropViewController *vc = [[ImageCropViewController alloc] init];
                vc.needNoAnimationDismiss = YES;
                vc.modalPresentationStyle = UIModalPresentationFullScreen;
                vc.originImage = photo;
                __weak typeof(self) weakSelf = self;
                vc.imageCropBlock = ^(UIImage * _Nonnull image) {
                    //得到裁剪图片返回
                    if (weakSelf.dataBlock) {
                        weakSelf.dataBlock(UIImagePNGRepresentation(image), nil);
                        [weakSelf dismissViewControllerAnimated:YES completion:nil];
                    }
                };
                [self presentViewController:vc animated:NO completion:nil];
                
            }else {
                [picker dismissViewControllerAnimated:YES completion:nil];
            }
        } else {
            [picker dismissViewControllerAnimated:YES completion:nil];
            NSLog(@"请选择图片");
        }
    }
}

#pragma mark - 懒加载
//从相册选择视频
- (UIImagePickerController *)moviePicker {
    if (_moviePicker == nil) {
        _moviePicker = [[UIImagePickerController alloc] init];
        _moviePicker.delegate = self;
        _moviePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        if (_cameraMode == CameraModeVideo) {
            _moviePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        } else {
            _moviePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
    }
    return _moviePicker;
}



/// UI相关

- (UIView *)timeView {
    if (!_timeView) {
        //时间视图
        _timeView = [[UIView alloc]init];
        _timeView.backgroundColor = [UIColor clearColor];
        _timeView.alpha = 0;
        
        UIView *backView = [[UIView alloc]init];
        backView.backgroundColor = [UIColor blackColor];
        backView.alpha = 0.38;
        backView.layer.cornerRadius = 15;
        backView.layer.masksToBounds = YES;
        backView.frame = CGRectMake(0, 0, 290, 36);
        [_timeView addSubview:backView];
        
        
        CGFloat timeWidth = [self widthWithText:@"00:00" Font:[UIFont systemFontOfSize:14] width:_screenWidth];
        
        _timeLabel = [[UILabel alloc]initWithFrame:CGRectMake((290 - timeWidth - 20)/2, 0, timeWidth + 20, 36)];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.text = @"00:00";
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.font = [UIFont systemFontOfSize:14];
        [_timeView addSubview:_timeLabel];
        
        UIView *redView = [[UIView alloc]init];
        redView.backgroundColor = [UIColor redColor];
        redView.layer.cornerRadius = 5;
        redView.layer.masksToBounds = YES;
        redView.frame = CGRectMake((290 - timeWidth - 20)/2 - 20, (36 - 10)/2, 10, 10);
        [_timeView addSubview:redView];
        _timeView.hidden = YES;
    }
    return _timeView;
}

- (CamareTopView *)topView {
    if (!_topView) {
        _topView = [[CamareTopView alloc]initWithFrame:CGRectMake(0, 0, _screenWidth, self.topViewHeight)];
        if (self.cameraMode == CameraModePictureAndVideo) {
            //可切换拍照视频，有切换摄像头按钮
            _topView.hideRightBtn = NO;
        } else {
            //单视频模式和单拍照没有切换摄像头按钮
            _topView.hideRightBtn = YES;
        }
        _topView.delegate = self;
    }
    return _topView;
}

- (CameraBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[CameraBottomView alloc]initWithFrame:CGRectMake(0, _screenHeight-self.bottomViewHeight-self.bottomViewBottom, _screenWidth, self.bottomViewHeight)];
        _bottomView.delegate = self;
    }
    return _bottomView;
}

- (CameraOnPatternBottomView *)onePatternBottomView {
    if (!_onePatternBottomView) {
        _onePatternBottomView = [[CameraOnPatternBottomView alloc]initWithFrame:CGRectMake(0, _screenHeight-self.bottomViewHeight-self.bottomViewBottom, _screenWidth, self.bottomViewHeight)];
        if (self.cameraMode == CameraModePicture) {
            [_onePatternBottomView setCameraType:1];
        } else if (self.cameraMode == CameraModeVideo) {
            [_onePatternBottomView setCameraType:2];
        }
        _onePatternBottomView.delegate = self;
    }
    return _onePatternBottomView;
}


#pragma mark - Helper
//存放视频的文件夹
- (NSString *)getVideoFolderWithName:(NSString *)name {
    NSString *cacheDir = NSTemporaryDirectory();
    NSString *direc = [cacheDir stringByAppendingPathComponent:@"videoFolder"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:direc]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:direc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    direc = [direc stringByAppendingPathComponent:name];
    return direc;
}

- (void)pinchGesture:(UIPinchGestureRecognizer*)sender {
    if (!self.cameraManager.videoDevice)
        return;
    
    if (sender.state == UIGestureRecognizerStateBegan)
    {
        _initialPinchZoom = self.cameraManager.videoDevice.videoZoomFactor;
    }
    
    if ([self.cameraManager.videoDevice lockForConfiguration:nil]) {
        CGFloat zoomFactor;
        zoomFactor =  _initialPinchZoom*pow(sender.scale < 1.0?8:2, (sender.scale - 1.0f));
        zoomFactor = MIN(5.0, zoomFactor);
        zoomFactor = MAX(1.0, zoomFactor);
        self.cameraManager.videoDevice.videoZoomFactor = zoomFactor;
        [self.cameraManager.videoDevice unlockForConfiguration];
    }
}

//检测相机权限
- (BOOL)checkCameraPermission {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied) {
        return NO;
    }else{
        return YES;
    }
    return YES;
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

- (CGFloat)widthWithText:(NSString *)text Font:(UIFont *)font width:(CGFloat)width
{
    CGSize sizeText =[text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    
    return sizeText.width;
}

@end
