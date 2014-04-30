//
//  AC_CoverEmblemView.h
//  AC Cover
//
//  Created by Hari Karam Singh on 17/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

@import UIKit;
@import CoreMotion;

@interface AC_CoverEmblemView : UIView


/** Designated initialiser for fixed size view */
+ (instancetype)coverEmblemView;

/** -1..1 for device rotation around x & y axes. Determines shadow offset */
@property (nonatomic) CGPoint relativeAngleOffset;


@end
