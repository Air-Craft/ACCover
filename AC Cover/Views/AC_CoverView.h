//
//  AC_CoverView.h
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface AC_CoverView : GLKView

/////////////////////////////////////////////////////////////////////////
#pragma mark - Calibration Extras
/////////////////////////////////////////////////////////////////////////
#ifdef AC_CALIBRATE

@property (nonatomic) float retraction;

- (void)setUniform:(NSString *)theName withFloat:(float)theValue;
- (void)setUniform:(NSString *)theName withVec4:(GLKVector4)theValue;


#endif

/** 
 Setup the GL context etc.
 @throws Exception on context or other init error
 @todo Proper exception type
 */
- (void)setup;

@end
