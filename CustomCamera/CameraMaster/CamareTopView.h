//
//  CamareTopView.h
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CamareTopViewDelegate <NSObject>
@optional
- (void)flashBtnClick:(BOOL)isLightOn;
- (void)changeBackAndFrontBtnClick:(BOOL)isFrontCamera;
@end
@interface CamareTopView : UIView
@property (nonatomic, assign)CGFloat topViewHeight;
@property (nonatomic, assign)BOOL isLightOn;
@property (nonatomic, assign)BOOL isFrontCamera;
@property (nonatomic, assign)BOOL hideRightBtn;
@property (nonatomic, assign)id <CamareTopViewDelegate>delegate;
@property (nonatomic,assign)UIDeviceOrientation deviceOrientation;
@end

NS_ASSUME_NONNULL_END
