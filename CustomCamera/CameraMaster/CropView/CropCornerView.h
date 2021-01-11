//
//  CropCornerView.h
//  CropCornerView
//
//  Created by tom on 2020/12/11.
//  Copyright © 2020 YS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CropCornerPosition) {
    CropCornerPositionLeftTop,
    CropCornerPositionRightTop,
    CropCornerPositionLeftBottom,
    CropCornerPositionRightBottom,
};

@interface CropCornerView : UIView

- (instancetype)initWithPosition:(CropCornerPosition)position;

@end
