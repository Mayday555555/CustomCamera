//
//  CameraNavigationController.m
//  TomDemo
//
//  Created by tom on 2020/12/16.
//

#import "CameraNavigationController.h"
#import "ImageCropViewController.h"
#import "CameraViewController.h"

@interface CameraNavigationController (){
    ImageCropViewController *cropVC;
    CameraViewController *cameraVC;
}
@end

@implementation CameraNavigationController

/// 不支持设备自动旋转
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (instancetype)initWithImage:(UIImage *)image {
    cropVC = [[ImageCropViewController alloc] init];
    cropVC.originImage = image;
    cropVC.imageCropBlock = self.imageCropBlock;
    self = [super initWithRootViewController:cropVC];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)initWithTakePictures {
    cameraVC = [[CameraViewController alloc] initWithCameraMode:CameraModePicture];
    self = [super initWithRootViewController:cameraVC];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)initWithPictureAndVideo {
    cameraVC = [[CameraViewController alloc] initWithCameraMode:CameraModePictureAndVideo];
    self = [super initWithRootViewController:cameraVC];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (instancetype)initWithVideo {
    cameraVC = [[CameraViewController alloc] initWithCameraMode:CameraModeVideo];
    self = [super initWithRootViewController:cameraVC];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

//- (void)setImageCropBlock:(void (^)(UIImage * _Nonnull))imageCropBlock {
//    _imageCropBlock = [imageCropBlock copy];
//    cropVC.imageCropBlock = _imageCropBlock;
//}

//- (void)setTakeImageBlock:(void (^)(UIImage * _Nonnull))takeImageBlock {
//    _takeImageBlock = [takeImageBlock copy];
//    takePicturesVC.takeImageBlock = _takeImageBlock;
//}

- (void)setDataBlock:(void (^)(NSData * _Nullable, NSData * _Nullable))dataBlock {
    _dataBlock = [dataBlock copy];
    cameraVC.dataBlock = _dataBlock;
}

@end
