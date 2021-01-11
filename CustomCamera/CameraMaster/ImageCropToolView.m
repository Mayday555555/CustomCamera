//
//  ImageCropToolView.m
//  CYImageCrop
//  底部工具栏
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import "ImageCropToolView.h"
#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define kScaleWidth(R) (R)*(SCREEN_WIDTH)/375.0
@interface ImageCropToolView()
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIButton *doneButton;
@property(nonatomic, strong) UIButton *rotateButton;
@end
@implementation ImageCropToolView
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addSubview:self.cancelButton];
        [self addSubview:self.doneButton];
        [self addSubview:self.rotateButton];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.cancelButton];
        [self addSubview:self.doneButton];
        [self addSubview:self.rotateButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat height =  self.bounds.size.height;
    CGFloat width =  self.bounds.size.width;
    CGFloat itemWH= kScaleWidth(58);
    self.cancelButton.frame = CGRectMake(30, (height-itemWH)/2, itemWH, itemWH);
    self.doneButton.frame = CGRectMake((width-itemWH)/2, (height-itemWH)/2, itemWH, itemWH);
    self.rotateButton.frame = CGRectMake(width-itemWH-30, (height-itemWH)/2, itemWH, itemWH);
}

#pragma mark  - action
- (void)cancelButtonAction {
    if (self.cancelBlock) {
        self.cancelBlock();
    }
}

- (void)doneButtonAction {
    if (self.confirmBlock) {
        self.confirmBlock();
    }
}

- (void)rotateButtonAction {
    if (self.ratateBlock) {
        self.ratateBlock();
    }
}

#pragma mark - 获取资源图片
- (UIImage *)getPictureWithName:(NSString *)name{
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"YSCrop" ofType:@"bundle"]];
    NSString *path   = [bundle pathForResource:name ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
}

#pragma mark - lazy load
- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton new];
        UIImage *image = [self getPictureWithName:@"ic_yscrop_close@3x"];
        [_cancelButton setImage:image forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _cancelButton;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton new];
        UIImage *image = [self getPictureWithName:@"ic_yscrop_done@3x"];
        [_doneButton setImage:image forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UIButton *)rotateButton {
    if (!_rotateButton) {
        _rotateButton = [UIButton new];
        UIImage *image = [self getPictureWithName:@"ic_yscrop_ratate@3x"];
        [_rotateButton setImage:image forState:UIControlStateNormal];
        [_rotateButton addTarget:self action:@selector(rotateButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rotateButton;
}

- (void)setDeviceRatate:(BOOL)deviceRatate {
    _deviceRatate = deviceRatate;
    if (deviceRatate) {
        //逆时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.doneButton.imageView.transform = CGAffineTransformMakeRotation(90 *M_PI / 180.0);
        CGAffineTransform transform = self.doneButton.imageView.transform;
        //第二个值表示横向放大的倍数，第三个值表示纵向缩小的程度
        transform = CGAffineTransformScale(transform, 1,1);
        self.doneButton.imageView.transform = transform;
        [UIView commitAnimations];
    }else {
        //顺时针 旋转90度
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.2]; //动画时长
        self.doneButton.imageView.transform = CGAffineTransformMakeRotation((M_PI * (0) / 180.0));
        CGAffineTransform transform = self.doneButton.imageView.transform;
        transform = CGAffineTransformScale(transform, 1,1);
        self.doneButton.imageView.transform = transform;
        [UIView commitAnimations];
    }
}

@end
