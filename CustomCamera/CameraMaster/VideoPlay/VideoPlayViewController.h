//
//  VideoPlayViewController.h
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol VideoPlayViewControllerDelegate <NSObject>
- (void)didSelectVideo;
@end
@interface VideoPlayViewController : UIViewController
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, assign) id <VideoPlayViewControllerDelegate>delegate;
@property (nonatomic, assign) BOOL lanscapeRecordRuning;
@end

NS_ASSUME_NONNULL_END
