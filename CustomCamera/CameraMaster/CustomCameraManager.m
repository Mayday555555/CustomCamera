//
//  CustomCameraManager.m
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/22.
//

#import "CustomCameraManager.h"
#import "MBProgressHUD.h"
//#import "Header.h"
@interface CustomCameraManager()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>

@property (nonatomic,assign) CameraMode cameraMode;
@property (nonatomic, assign) UIDeviceOrientation            startRecordOrientation;//开始录制时候的屏幕方向
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;//用于显示摄像头画面
/*相机配置*/
@property (nonatomic,assign) AVCaptureSessionPreset videoQuality;//默认：AVCaptureSessionPreset1920x1080
@property (nonatomic, assign) CGSize                        outputSize;//视频分辨率大小
@property (nonatomic, strong) AVCaptureSession              *session;
@property (nonatomic, strong) AVCaptureDeviceInput          *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput          *audioInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput      *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput      *audioOutput;
@property (nonatomic, strong) AVCapturePhotoOutput          *imageOutput;//照片输出流
@property (nonatomic, assign) AVCaptureFlashMode            flashMode;//闪光灯模式
/*线程*/
@property (nonatomic, strong) dispatch_queue_t              videoQueue;//视频对应线程
@property (nonatomic, strong) dispatch_queue_t              audioQueue;//音频对应线程
@property (nonatomic, strong) dispatch_queue_t              writeQueue;//视频写入线程
/*写入*/
@property (nonatomic, strong) NSURL                         * videoUrl;
@property (nonatomic, strong) NSURL                         * nVideoUrl;
@property (nonatomic, strong) AVAssetWriter                 *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput            *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInput            *assetWriterAudioInput;

/*控制控件显示的timer*/
@property (nonatomic, strong) NSTimer                      *recodeTimer;
@property (nonatomic, assign) int                           recodeTime;

@property (nonatomic,assign) CMTime timeOffset;//录制的偏移CMTime
@property (nonatomic,assign) CMTime lastVideo;//记录上一次视频数据文件的CMTime
@property (nonatomic,assign) CMTime lastAudio;//记录上一次音频数据文件的CMTime
@end

@implementation CustomCameraManager

#pragma mark - 对外方法
- (instancetype)initWithCameraMode:(CameraMode)cameraMode {
    self = [super init];
    if (self) {
        _cameraMode = cameraMode;
        _videoQuality = AVCaptureSessionPreset1920x1080;
        _maxVideoDuration = 300;
        _videoState = 1;
        _isPause = NO;
        _discount = NO;
        _videoQueue = dispatch_queue_create("com.Heee.video", DISPATCH_QUEUE_SERIAL);
        _audioQueue = dispatch_queue_create("com.Heee.audio", DISPATCH_QUEUE_SERIAL);
        _writeQueue = dispatch_queue_create("com.Heee.write", DISPATCH_QUEUE_SERIAL);
        self.videoUrl = [[NSURL alloc] initFileURLWithPath:[self getVideoFolderWithName:@"video.mp4"]];
        [self configCamera];
    }
    
    return self;
}

- (void)startRunningSession:(BOOL)start {
    if (start) {
        if (!self.session.isRunning) {
            //开始显示画面
            [self.session startRunning];
        }
    } else {
        if (self.session.isRunning) {
            [self.session stopRunning];
        }
    }
}

- (void)setLightOnWithFlashMode:(AVCaptureFlashMode)flashMode torchMode:(AVCaptureTorchMode)torchMode {
    if ([_videoDevice hasFlash]) {
        if ([self.videoDevice lockForConfiguration:nil]) {
            if (flashMode != -1) {
                [self setPictureFlashMode:flashMode];
            }
            if (torchMode != -1) {
                [self setVideoTorchMode:torchMode];
            }
            
            [self.videoDevice unlockForConfiguration];
        }
    }
}

- (void)changeFrontAndBackCamera {
    [self switchCameraButtonClick];
}

- (void)resetData {
    _videoState = 1;
    [self setLightOnWithFlashMode:AVCaptureFlashModeOff torchMode:AVCaptureTorchModeOff];
    [self destroyWrite];
    [self startTimer:NO];
}

- (BOOL)takePicture {
    AVCaptureConnection *videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection ==  nil) {
        return NO;
    }
    
    //前置摄像头时，设置镜像图片
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if (position == AVCaptureDevicePositionFront) {
        videoConnection.videoMirrored = YES;
    }
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    photoSettings.flashMode = self.flashMode;
    [self.imageOutput capturePhotoWithSettings:photoSettings delegate:self];
    return YES;
}


#pragma mark -  相机初始化
- (void)configCamera {
    //使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    
    [self.session beginConfiguration];//开始
    [self.session setSessionPreset:self.videoQuality];
    
    //添加视频输入
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if (self.cameraMode != CameraModePicture) {
        //添加语音输入
        AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:(AVCaptureDevicePositionUnspecified)];
        AVCaptureDevice *audioCaptureDevice = deviceDiscoverySession.devices.firstObject;
        self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:nil];
        if ([self.session canAddInput:self.audioInput]) {
            [self.session addInput:self.audioInput];
        }
    }
    
    //添加视频输出
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = [self.previewLayer connection].videoOrientation;
    AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    if ([self.videoDevice.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
        [connection setPreferredVideoStabilizationMode:stabilizationMode];
    }
    
    //添加语音输出
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
    //添加图像输出
    if (self.cameraMode != CameraModeVideo) {
        self.imageOutput = [[AVCapturePhotoOutput alloc] init];
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
    }
    
    [self.session commitConfiguration];
    
    [self setupPreviewLayer];
    
    [self.videoDevice unlockForConfiguration];
    
    NSArray *arr = [self.videoQuality componentsSeparatedByString:@"x"];
    if (arr.count == 2) {
        NSString *firstSize = [self getNumberFromStr:arr[1]];
        NSString *secondSize = [self getNumberFromStr:arr[0]];
        _outputSize = CGSizeMake(firstSize.integerValue, secondSize.integerValue);
    }
}

#pragma mark - 视频写入设置
//设置写入属性
- (void)setupWriter {
    
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.videoUrl fileType:AVFileTypeMPEG4 error:nil];
    
    //视频
    if (@available(iOS 11.0, *)) {
        NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecTypeH264,
                                                   AVVideoWidthKey : @(self.outputSize.height),
                                                   AVVideoHeightKey : @(self.outputSize.width), AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill};
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    } else {
        NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                                   AVVideoWidthKey : @(self.outputSize.height),
                                                   AVVideoHeightKey : @(self.outputSize.width), AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill};
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    }
    //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
    _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
    if ([self.assetWriter canAddInput:_assetWriterVideoInput]) {
        [self.assetWriter addInput:_assetWriterVideoInput];
    }
    
    //音频
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                               AVEncoderBitRateKey:@(128000),
                                               AVSampleRateKey:@(44100),
                                               AVNumberOfChannelsKey:@(1)};
    self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
    self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    if ([self.assetWriter canAddInput:self.assetWriterAudioInput]) {
        [self.assetWriter addInput:self.assetWriterAudioInput];
    }
    
    self.videoState = 2;
}


- (void)startVideoWrite {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.videoUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.videoUrl path] error:nil];
    }
    self.startRecordOrientation = self.deviceOrientation;
    [self setupWriter];
    [self startTimer:YES];
    self.timeOffset = CMTimeMake(0, 0);
}

//暂停录制/继续录制
- (void)pauseAndResumeVideoWrite {
    if (!self.isPause) {
        [self pauseVideoWrite];
    } else {
        [self resumeVideoWrite];
    }
}

//暂停录制视频
- (void)pauseVideoWrite {
    @synchronized (self) {
        if (self.videoState == 2) {
            self.isPause = YES;
            self.discount = YES;
            [self pauseTimer];
        }
    }
}

// 继续录制视频
- (void)resumeVideoWrite {
    @synchronized (self) {
        if (self.isPause) {
            self.isPause = NO;
            [self resumeTimer];
        }
    }
    
}

- (void)stopVideoWrite {
    _videoState = 3;
    [self startTimer:NO];
    //完成拍摄，关掉闪光灯
    if ([_videoDevice lockForConfiguration:nil]) {
        [_videoDevice setTorchMode:AVCaptureTorchModeOff];
        [_videoDevice unlockForConfiguration];
    }
    
    __weak __typeof(self)weakSelf = self;
    if(self.assetWriter && self.assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            //视频
            [weakSelf.assetWriter finishWritingWithCompletionHandler:^{
                if (weakSelf.startRecordOrientation == UIDeviceOrientationLandscapeLeft) {
                    [self fixVideoDirection:UIDeviceOrientationLandscapeLeft];
                } else if (weakSelf.startRecordOrientation == UIDeviceOrientationLandscapeRight) {
                    [self fixVideoDirection:UIDeviceOrientationLandscapeRight];
                }else {//if (weakSelf.startRecordOrientation == UIDeviceOrientationPortrait)
                    if (self.delegate && [self.delegate respondsToSelector:@selector(finishVideoWrite:url:isLandscapeRecord:)]) {
                        [self.delegate finishVideoWrite:YES url:self.videoUrl isLandscapeRecord:NO];
                    }
                }
                
                [weakSelf destroyWrite];
            }];
        });
    } else {
        //todo
        if (self.delegate && [self.delegate respondsToSelector:@selector(finishVideoWrite:url:isLandscapeRecord:)]) {
            [self.delegate finishVideoWrite:NO url:nil isLandscapeRecord:NO];
        }
//        [self reset];
//        [self clearPicture];
    }
}


#pragma mark - 修正视频方向
- (void)fixVideoDirection:(UIDeviceOrientation)orientation {
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    AVAssetExportSession *_assetExport = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPreset1920x1080];
    _assetExport.outputFileType = AVFileTypeMPEG4;
    self.nVideoUrl = [[NSURL alloc] initFileURLWithPath:[self getVideoFolderWithName:@"newVideo.mp4"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.nVideoUrl path]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self.nVideoUrl path] error:nil];
    }
    _assetExport.outputURL = self.nVideoUrl;
    _assetExport.videoComposition = [self getComposition:asset orientation:orientation];
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showHUDAddedTo:[self getCurrentVC].view animated:YES];
    });
    __weak typeof (self) weakSelf = self;
    [_assetExport exportAsynchronouslyWithCompletionHandler:^(void ) {
        if (_assetExport.status == AVAssetExportSessionStatusCompleted) {
            //视频处理完成
            dispatch_sync(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:[self getCurrentVC].view animated:YES];
                if (self.delegate && [self.delegate respondsToSelector:@selector(finishVideoWrite:url:isLandscapeRecord:)]) {
                    [self.delegate finishVideoWrite:YES url:self.nVideoUrl isLandscapeRecord:YES];
                }
            });
        }else{
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(finishVideoWrite:url:isLandscapeRecord:)]) {
                    [weakSelf.delegate finishVideoWrite:NO url:nil isLandscapeRecord:NO];
                }
                NSLog(@"视频处理失败");
                [MBProgressHUD hideHUDForView:[self getCurrentVC].view animated:YES];
            });
        }
    }];
}

- (AVMutableVideoComposition *)getComposition:(AVAsset *)videoAsset orientation:(UIDeviceOrientation)orientation{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    // 视频转向
    CGAffineTransform translateToCenter;
    CGAffineTransform mixedTransform;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    NSArray *tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
    NSLog(@"width%fheight%f",videoTrack.naturalSize.width,videoTrack.naturalSize.height);
    
//    if (degrees == 90) {
//        // 顺时针旋转90°
//        translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
//        mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
//        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
//    } else if(degrees == 180){
//        // 顺时针旋转180°
//        translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
//        mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
//        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
//    } else {
//        // 顺时针旋转270°
//        translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
//        mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
//        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
//    }
    if (orientation == UIDeviceOrientationLandscapeLeft) {
        translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
        mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
        mixedTransform = CGAffineTransformTranslate(mixedTransform, videoTrack.naturalSize.width, videoTrack.naturalSize.height);
        mixedTransform = CGAffineTransformRotate(mixedTransform, M_PI);
        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
    } else {
        translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
        mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
        videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
    }
    
    
    AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
    AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
    
    roateInstruction.layerInstructions = @[roateLayerInstruction];
    // 加入视频方向信息
    videoComposition.instructions = @[roateInstruction];
    return videoComposition;
}


- (AVMutableVideoComposition *)getComposition1:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)){
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
    }
    composition.naturalSize    = videoSize;
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}

- (void)destroyWrite {
    self.assetWriterAudioInput = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
}

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
    NSData *imageData = [photo fileDataRepresentation];
    if ([self.delegate respondsToSelector:@selector(getPictureData:)]) {
        [self.delegate getPictureData:imageData];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL isVideo = YES;
    @synchronized (self) {
        if (self.videoState != 2 || self.isPause) {
            return;
        }
        if (captureOutput != self.videoOutput) {
            isVideo = NO;
        }
        
        if (self.discount) {
            if (isVideo) {
                return;
            }
            self.discount = NO;
            //计算暂停的时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = isVideo ? self.lastVideo : self.lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }else {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            //根据得到的timeOffset调整
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (isVideo) {
            self.lastVideo = pts;
        }else {
            self.lastAudio = pts;
        }
        
//        CFRelease(sampleBuffer);
    }
    
    
    @autoreleasepool {
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            @synchronized(self) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
            }
        }
        
        //音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
            @synchronized(self) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
            }
        }
    }
    
    
}

//开始写入数据
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if (sampleBuffer == NULL){
        return;
    }
    
    @synchronized(self){
        if (self.videoState != 2){
            return;
        }
    }
    
//    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        @autoreleasepool {
            @synchronized(self) {
                if (self.videoState != 2){
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            if (self.assetWriter.status != AVAssetWriterStatusWriting) {
                [self.assetWriter startWriting];
                CMTime start_recording_time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                CMTime startingTimeDelay = CMTimeMakeWithSeconds(0.1, 1000000000);
                CMTime startTimeToUse = CMTimeAdd(start_recording_time, startingTimeDelay);
                [self.assetWriter startSessionAtSourceTime:startTimeToUse];
            }
            
            //写入视频数据
            if (mediaType == AVMediaTypeVideo && self.assetWriterVideoInput.readyForMoreMediaData) {
                [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
            }
            
            //写入音频数据
            if (mediaType == AVMediaTypeAudio && self.assetWriterAudioInput.readyForMoreMediaData) {
                [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            }
            
            CFRelease(sampleBuffer);
        }
    });
}


#pragma mark - 画面显示设置
- (void)setupPreviewLayer  {
    //添加画面显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.previewLayer.cornerRadius = 1;
    self.previewLayer.masksToBounds = YES;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)addPreviewLayerToView:(UIView *)view {
    [view.layer addSublayer:self.previewLayer];
}

- (void)setPreviewLayerFrame:(CGRect)rect {
    self.previewLayer.frame = rect;
}

#pragma mark - 定时器
- (void)startTimer:(BOOL)start {
    if (start) {
        if (self.recodeTimer == nil) {
            self.recodeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshRecodeTime) userInfo:nil repeats:YES];
        }
    } else {
        if (self.recodeTimer) {
            [self.recodeTimer invalidate];
            self.recodeTimer = nil;
        }
        self.recodeTime = 0;
    }
}

- (void)pauseTimer {
    if (self.recodeTimer) {
        [self.recodeTimer setFireDate:[NSDate distantFuture]];
    }
}

- (void)resumeTimer {
    if (self.recodeTimer) {
        [self.recodeTimer setFireDate:[NSDate distantPast]];
    }
}

- (void)refreshRecodeTime {
    if (_recodeTime >= _maxVideoDuration) {
        [self stopVideoWrite];
        return;
    }
    _recodeTime++;
    
    NSString *timeStr = @"";
    if (_recodeTime < 60) {
        timeStr = [NSString stringWithFormat:@"00:%02d",_recodeTime];
    }else if (_recodeTime < 60*60) {
        timeStr = [NSString stringWithFormat:@"%02d:%02d",_recodeTime/60,_recodeTime%60];
    }else{
        int hour = _recodeTime/3600;
        int min = (_recodeTime - hour*3600)/60;
        int sec = _recodeTime%60;
        timeStr = [NSString stringWithFormat:@"%d:%02d:%02d",hour,min,sec];
    }
    if ([self.delegate respondsToSelector:@selector(refreshTime:)]) {
        [self.delegate refreshTime:timeStr];
    }
}

#pragma mark - 相机设置
- (void)setPictureFlashMode:(AVCaptureFlashMode)mode {
    if ([self supportedFlashMode:mode]) {
        self.flashMode = mode;
    }
}

- (void)setVideoTorchMode:(AVCaptureTorchMode)mode {
    if ([self.videoDevice isTorchModeSupported:mode]) {
        [self.videoDevice setTorchMode:mode];
    }
}

/// 获取是否支持闪光灯模式
- (BOOL)supportedFlashMode:(AVCaptureFlashMode)flashMode {
    for (NSNumber *num in self.imageOutput.supportedFlashModes) {
        if (num.intValue == flashMode) {
            return YES;
        }
    }
    
    return NO;
}

/// 切换前置/后置相机
- (void)switchCameraButtonClick {
    AVCaptureDevice *newCamera = nil;
    AVCaptureDeviceInput *newInput = nil;
    //获取当前相机的方向(前还是后)
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if (position == AVCaptureDevicePositionFront) {
        //获取后置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }else{
        //获取前置摄像头
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }
    
    //输入流
    newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
    if (newInput != nil) {
        [self.session beginConfiguration];
        //先移除原来的input
        [self.session removeInput:self.videoInput];
        
        if (position == AVCaptureDevicePositionBack) {
            if ([UIScreen mainScreen].bounds.size.height == 480) {
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset640x480];
                }
            }else{
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
                }
            }
        }else{
            if ([UIScreen mainScreen].bounds.size.height == 480) {
                if ([self.session canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
                    [self.session setSessionPreset:AVCaptureSessionPresetiFrame960x540];
                }
            }else{
                if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
                }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
                }
            }
        }
        
        if ([self.session canAddInput:newInput]) {
            [self.session addInput:newInput];
            self.videoInput = newInput;
        } else {
            //如果不能加现在的input，就加原来的input
            [self.session addInput:self.videoInput];
        }
        
        [self.session commitConfiguration];
    }
}


#pragma mark - getter
/// 获取设备
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    //内置广角相机                                              AVCaptureDeviceTypeBuiltInWideAngleCamera
    //广角相机和长焦相机的组合，创建了一个拍照，录像的AVCaptureDevic   AVCaptureDeviceTypeBuiltInDualCamera iOS12
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera,AVCaptureDeviceTypeBuiltInDualCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray *devices = deviceDiscoverySession.devices;
    for (AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
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

- (NSString *)getNumberFromStr:(NSString *)str {
    NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return[[str componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
}

- (void)changeMovToMp4:(NSURL *)mediaURL dataBlock:(void (^)(NSURL *url))handler {
    AVAsset *video = [AVAsset assetWithURL:mediaURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:video presetName:AVAssetExportPreset1280x720];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeMPEG4;
    NSString *path = [self getVideoFolderWithName:@"video.mp4"];
    self.videoUrl = [NSURL fileURLWithPath:path];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exportSession.outputURL = self.videoUrl;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        handler(self.videoUrl);
    }];
}

//获取视频封面图
- (void)movieToImageWithUrl:(NSURL *)url handler:(void (^)(UIImage *movieImage))handler {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        } else {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

- (UIViewController *)getCurrentVC // 获取当前屏幕显示的viewcontroller
{
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    
    return currentVC;
}

- (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC = nil;
    
    if ([rootVC presentedViewController]) // 视图是被presented出来的
    {
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) // 根视图为UITabBarController
    {
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        
    }
    else if ([rootVC isKindOfClass:[UINavigationController class]]) // 根视图为UINavigationController
    {
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        
    }
    else // 根视图为非导航类
    {
        currentVC = rootVC;
    }
    
    return currentVC;
}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

@end
