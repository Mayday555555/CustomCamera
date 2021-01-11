//
//  CustomVideoPlayView.m
//  VideoTest
//
//  Created by tom on 2020/12/16.
//

#import "CustomVideoPlayView.h"
@interface CustomVideoPlayView()
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *labelCurrentTime;
@property (nonatomic, strong) UILabel *labelTotalTime;
@property (nonatomic, strong) id playbackTimerObserver;
@property (nonatomic, strong) AVURLAsset *asset;
@end

@implementation CustomVideoPlayView

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame withShowInView:(UIView *)bgView url:(NSURL *)url {
    if (self = [self initWithFrame:frame]) {
        //创建播放器层
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.playerLayer.frame = self.bounds;
        
        [self.layer addSublayer:self.playerLayer];
        
        [self setupUI];
        if (url) {
            self.videoUrl = url;
        }
        [bgView addSubview:self];
    }
    return self;
}

- (void)dealloc {
    [self removeAvPlayerNtf];
    [self stopPlayer];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    self.player = nil;
    #pragma clang diagnostic pop
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:[self getAVPlayerItem]];
        [self addAVPlayerNtf:_player.currentItem];
        
    }
    
    return _player;
}

- (AVPlayerItem *)getAVPlayerItem {
    AVPlayerItem *playerItem=[AVPlayerItem playerItemWithURL:self.videoUrl];
    return playerItem;
}


#pragma mark - 初始化视频
- (void)setVideoUrl:(NSURL *)videoUrl {
    _videoUrl = videoUrl;
    [self removeAvPlayerNtf];
    [self setupPlayerWithUrl:videoUrl];
}

//- (void)assetWithUrl:(NSURL *)url {
//    BOOL value = YES;
//    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(value)};
//    self.asset = [[AVURLAsset alloc]initWithURL:url options:options];
//    NSArray *keys = @[@"duration"];
//    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
//        NSError *error = nil;
//        AVKeyValueStatus tracksStatus =  [self.asset statusOfValueForKey:@"duration" error:&error];
//        if (tracksStatus == 0) {
//            NSLog(@"AVKeyValueStatusUnknown");
//        } else if (tracksStatus == 1) {
//            NSLog(@"AVKeyValueStatusLoading");
//        } else if (tracksStatus == 2) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (!CMTIME_IS_INDEFINITE(self.asset.duration)) {
//                    float second = self.asset.duration.value / self.asset.duration.timescale;
//                    self.slider.minimumValue = 0;
//                    self.slider.maximumValue = second;
//                    self.labelTotalTime.text = [self convertTime:second];
//                }
//            });
//        } else if (tracksStatus == 3) {
//            NSLog(@"AVKeyValueStatusFailed");
//        } else if (tracksStatus == 4) {
//            NSLog(@"AVKeyValueStatusCancelled");
//        }
//    }];
//
//    [self setupPlayerWithAsset:self.asset];
//}

- (void)setupPlayerWithUrl:(NSURL *)url {
    [self.player seekToTime:CMTimeMakeWithSeconds(0, _player.currentItem.duration.timescale)];
    [self.player replaceCurrentItemWithPlayerItem:[self getAVPlayerItem]];
    
    [self addPeriodicTimeObserver];
    [self addAVPlayerNtf:self.player.currentItem];
    [self play];
}

- (void)addPeriodicTimeObserver {
    __weak typeof(self) weakSelf = self;
    self.playbackTimerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        CGFloat value = weakSelf.player.currentItem.currentTime.value / weakSelf.player.currentItem.currentTime.timescale;
        NSLog(@"slider value %f",value);
        weakSelf.slider.value = value;
        weakSelf.labelCurrentTime.text = [weakSelf convertTime:value];
        
        if ([weakSelf.labelTotalTime.text isEqualToString:@"00:00"]) {
            float second = weakSelf.player.currentItem.duration.value / weakSelf.player.currentItem.duration.timescale;
            weakSelf.labelTotalTime.text = [weakSelf convertTime:second];
        }
    }];
}

- (NSString *)convertTime:(float)second {
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSince1970:(NSTimeInterval)second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = @"mm:ss";
    NSString *showStr = [formatter stringFromDate:date];
    return showStr;
}

#pragma mark - 播放视频  停止视频

- (void)stopPlayer {
    if (self.player.rate == 1) {
        [self.player pause];//如果在播放状态就停止
    }
}

- (void)play {
    if (self.player.rate == 0) {
        [self.player play];
    }
}


#pragma mark - kvo 通知
- (void) addAVPlayerNtf:(AVPlayerItem *)playerItem {
    //监控状态属性
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)removeAvPlayerNtf {
    AVPlayerItem *playerItem = self.player.currentItem;
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.player removeTimeObserver:self.playbackTimerObserver];
}



/**
 *  通过KVO监控播放器状态
 *
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status==AVPlayerStatusReadyToPlay){
            NSLog(@"正在播放...，视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!CMTIME_IS_INDEFINITE(playerItem.duration)) {
                    float second = playerItem.duration.value / playerItem.duration.timescale;
                    self.slider.minimumValue = 0;
                    self.slider.maximumValue = second;
                    self.labelTotalTime.text = [self convertTime:second];
                }
            });
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array=playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        NSLog(@"共缓冲：%.2f",totalBuffer);
    }
}

- (void)playbackFinished:(NSNotification *)ntf {
    [self.player seekToTime:CMTimeMake(0, 1)];
//    [self.player play];
    if ([self.delegate respondsToSelector:@selector(playbackFinished)])
    {
        [self.delegate playbackFinished];
    }
}

#pragma mark UI 控件
- (void)setupUI {
    self.backgroundColor = [UIColor blackColor];
    self.labelCurrentTime.frame = CGRectMake(20, self.bounds.size.height - 31, 35, 16);
    [self addSubview:self.labelCurrentTime];
    self.slider.frame = CGRectMake(60, self.bounds.size.height - 31, self.bounds.size.width - 10 - 55 * 2, 16);
    [self addSubview:self.slider];
    self.labelTotalTime.frame = CGRectMake(self.bounds.size.width - 55, self.bounds.size.height - 31, 35, 16);
    [self addSubview:self.labelTotalTime];
    
}

- (void)resetUI:(CGRect)bounds {
    self.playerLayer.frame = bounds;
    self.labelCurrentTime.frame = CGRectMake(20, bounds.size.height - 31, 35, 16);
    self.slider.frame = CGRectMake(60, bounds.size.height - 31, bounds.size.width - 10 - 55 * 2, 16);
    self.labelTotalTime.frame = CGRectMake(bounds.size.width - 55, bounds.size.height - 31, 35, 16);
}

- (UISlider *)slider {
    if (!_slider) {
        _slider = [[UISlider alloc]init];
        _slider.tintColor = [UIColor whiteColor];
        [_slider setThumbImage:[self imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        [_slider addTarget:self action:@selector(sliderChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 4.0f, 4.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *originalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect rectRound = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
       
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, 0.0);
   
    CGFloat cornerRadius = MIN(originalImage.size.width, originalImage.size.height) * 0.5;
   
    [[UIBezierPath bezierPathWithRoundedRect:rectRound
                               cornerRadius:cornerRadius] addClip];
   
    [originalImage drawInRect:rectRound];
   
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
   
   UIGraphicsEndImageContext();
    
    return image;
}

- (UILabel *)labelCurrentTime {
    if (!_labelCurrentTime) {
        _labelCurrentTime = [[UILabel alloc]init];
        _labelCurrentTime.text = @"00:00";
        _labelCurrentTime.textColor = [UIColor whiteColor];
        _labelCurrentTime.font = [UIFont systemFontOfSize:12];
    }
    return _labelCurrentTime;
}

- (UILabel *)labelTotalTime {
    if (!_labelTotalTime) {
        _labelTotalTime = [[UILabel alloc]init];
        _labelTotalTime.text = @"00:00";
        _labelTotalTime.textColor = [UIColor whiteColor];
        _labelTotalTime.font = [UIFont systemFontOfSize:12];
    }
    return _labelTotalTime;
}

- (void)sliderChanged {
    CMTime time = CMTimeMake(self.slider.value *self.player.currentItem.currentTime.timescale, self.player.currentItem.currentTime.timescale);
    [self.player.currentItem seekToTime:time];
}

@end
