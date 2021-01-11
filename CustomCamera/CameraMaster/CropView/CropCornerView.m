//
//  CropCornerView.h
//  CropCornerView
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import "CropCornerView.h"

static const CGFloat kCornerWidth = 4.0;
static const CGFloat kCornerLength = 20.0;

@implementation CropCornerView

- (instancetype)initWithPosition:(CropCornerPosition)position {
    self = [super initWithFrame:CGRectMake(0, 0, kCornerLength, kCornerLength)];
    if (!self) { return nil; }
    
    CALayer *rectLayer = [CALayer layer];
    rectLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:rectLayer];
    
    CALayer *squareLayer = [CALayer layer];
    squareLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:squareLayer];
    
    switch (position) {
        case CropCornerPositionLeftTop:
            rectLayer.frame = CGRectMake(0, 0, kCornerWidth, kCornerLength);
            squareLayer.frame = CGRectMake(kCornerWidth, 0, kCornerLength-kCornerWidth, kCornerWidth);
            break;
        case CropCornerPositionRightTop:
            rectLayer.frame = CGRectMake(kCornerLength-kCornerWidth, 0, kCornerWidth, kCornerLength);
            squareLayer.frame = CGRectMake(0, 0, kCornerLength-kCornerWidth, kCornerWidth);
            break;
        case CropCornerPositionLeftBottom:
            rectLayer.frame = CGRectMake(0, 0, kCornerWidth, kCornerLength);
            squareLayer.frame = CGRectMake(kCornerWidth, kCornerLength-kCornerWidth, kCornerLength-kCornerWidth, kCornerWidth);
            break;
        case CropCornerPositionRightBottom:
            rectLayer.frame = CGRectMake(kCornerLength-kCornerWidth, 0, kCornerWidth, kCornerLength);
            squareLayer.frame = CGRectMake(0, kCornerLength-kCornerWidth, kCornerLength-kCornerWidth, kCornerWidth);
            break;
    }
    
    return self;
}

@end
