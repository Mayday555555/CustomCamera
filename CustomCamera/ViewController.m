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
    [self presentViewController:vc animated:YES completion:nil];
}
- (IBAction)clickPictureMake:(id)sender {
    CameraViewController *vc = [[CameraViewController alloc]initWithCameraMode:CameraModePicture];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)clickToCanChange:(id)sender {
    CameraViewController *vc = [[CameraViewController alloc]initWithCameraMode:CameraModePictureAndVideo];
    [self presentViewController:vc animated:YES completion:nil];
}


//获得视频存放地址
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_091748.mp4"] ;
//    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_091535.mp4"];
    return videoCache;
}





@end
