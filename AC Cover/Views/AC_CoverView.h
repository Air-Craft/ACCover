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


// TEMP
@property (nonatomic) float retraction;
@property (nonatomic) CGPoint light0Position;
@property (nonatomic) float light0Intensity;
@property (nonatomic) CGPoint light1Position;
@property (nonatomic) float light1Intensity;
@property (nonatomic) float faceDiffuse;
@property (nonatomic) float faceSpecular;
@property (nonatomic) float edgeDiffuse;
@property (nonatomic) float edgeSpecular;


/** 
 Setup the GL context etc.
 @throws Exception on context or other init error
 @todo Proper exception type
 */
- (void)setup;

@end
