//
//  AC_CoverView.h
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

@import UIKit;
@import CoreMotion;
@import GLKit;

@interface AC_CoverView : GLKView

/////////////////////////////////////////////////////////////////////////
#pragma mark - Calibration Extras
/////////////////////////////////////////////////////////////////////////
#ifdef AC_CALIBRATE

@property (nonatomic) float retraction;

- (void)setUniform:(NSString *)theName withFloat:(float)theValue;
- (void)setUniform:(NSString *)theName withVec4:(GLKVector4)theValue;


#endif


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

/** 
 Setup the GL context etc.
 @throws Exception on context or other init error
 @todo Proper exception type
 */
- (void)setupWithMotionManager:(CMMotionManager *)motionManger;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

/** -1..1 for device rotation around x & y axes. Determines shadow offset */
@property (nonatomic) CGPoint relativeAngleOffset;

/** In points. Converted internally */
@property (nonatomic) CGPoint globalPositionOffset;



@end
