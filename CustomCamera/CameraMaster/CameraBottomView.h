//
//  CameraBottomView.h
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CameraBottomViewDelegate <NSObject>
@optional
- (void)closeBtnClick;
- (void)centerBtnClick;
- (void)changeCameraTypeBtnClick;
- (void)playBtnClick;
@end
@interface CameraBottomView : UIView
@property (nonatomic, assign)CGFloat bottomViewHeight;
//@property (nonatomic, assign)NSInteger cameraTyp;//1拍照 2录视频
//@property (nonatomic, assign)NSInteger videoState;//1未开始 2.正在录视频 3.录制完成
//@property (nonatomic, assign)BOOL isPlaying;//视频是否正在播放；
@property (nonatomic, assign)id <CameraBottomViewDelegate>delegate;
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
- (void)setVideoState:(NSInteger)videoState;
- (void)setIsPlaying:(BOOL)isPlaying;
- (void)setCameraType:(NSInteger)cameraType;
@end

NS_ASSUME_NONNULL_END
