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

/** 
 Setup the GL context etc.
 @throws Exception on context or other init error
 @todo Proper exception type
 */
- (void)setup;

@end
