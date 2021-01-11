//
//  CustomVideoPlayView.h
//  VideoTest
//
//  Created by tom on 2020/12/16.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CustomVideoPlayViewDelegate <NSObject>
- (void)playbackFinished;
@end


@interface CustomVideoPlayView : UIView

@property (nonatomic,assign) id<CustomVideoPlayViewDelegate>delegate;
@property (nonatomic,strong) AVPlayer *player;//播放器对象
@property (nonatomic,strong) AVPlayerLayer *playerLayer;

- (instancetype)initWithFrame:(CGRect)frame withShowInView:(UIView *)bgView url:(NSURL *)url;

@property (copy, nonatomic) NSURL *videoUrl;

- (void)stopPlayer;
- (void)play;
- (void)resetUI:(CGRect)bounds;
@end

NS_ASSUME_NONNULL_END
