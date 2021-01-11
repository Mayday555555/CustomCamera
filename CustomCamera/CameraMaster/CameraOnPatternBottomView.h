//
//  CameraOnPatternBottomView.h
//  EagleCloud
//
//  Created by 陈铉泽 on 2020/12/18.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CameraOnPatternBottomViewDelegate <NSObject>
@optional
- (void)onlyVideoCloseBtnClick;
- (void)onlyVideoCenterBtnClick;
- (void)albumBtnClick;
- (void)pauseBtnClick;
@end
@interface CameraOnPatternBottomView : UIView
@property (nonatomic, assign)CGFloat bottomViewHeight;
//@property (nonatomic, assign)NSInteger cameraTyp;//1拍照 2录视频
//@property (nonatomic, assign)NSInteger videoState;//1未开始 2.正在录视频 3.录制完成
@property (nonatomic, assign)id <CameraOnPatternBottomViewDelegate>delegate;
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
- (void)setVideoState:(NSInteger)videoState;
- (void)setCameraType:(NSInteger)cameraType;
- (void)setPause:(BOOL)isPause;
@end

NS_ASSUME_NONNULL_END
