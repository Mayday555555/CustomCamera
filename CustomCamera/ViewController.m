//
//  ViewController.m
//  VideoTest
//
//  Created by 陈铉泽 on 2020/12/14.
//

#import "ViewController.h"
#import "CameraViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)clickToVideoMake:(id)sender {
    CameraViewController *vc = [[CameraViewController alloc]initWithCameraMode:CameraModeVideo];
    vc.dataBlock = ^(NSData * _Nullable imageData, NSData * _Nullable videoData) {
        if (videoData != nil) {
            NSLog(@"拍视频成功");
        }
    };
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)clickPictureMake:(id)sender {
    CameraViewController *vc = [[CameraViewController alloc]initWithCameraMode:CameraModePicture];
    vc.dataBlock = ^(NSData * _Nullable imageData, NSData * _Nullable videoData) {
        if (imageData != nil) {
            NSLog(@"拍图片成功");
        }
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)clickToCanChange:(id)sender {
    CameraViewController *vc = [[CameraViewController alloc]initWithCameraMode:CameraModePictureAndVideo];
    vc.dataBlock = ^(NSData * _Nullable imageData, NSData * _Nullable videoData) {
        if (videoData != nil) {
            NSLog(@"拍视频成功");
        }
        if (imageData != nil) {
            NSLog(@"拍图片成功");
        }
    };
    [self presentViewController:vc animated:YES completion:nil];
}


//获得视频存放地址
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_091748.mp4"] ;
//    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_091535.mp4"];
    return videoCache;
}





@end
