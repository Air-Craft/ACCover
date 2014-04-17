//
//  AC_CoverEmblemView.m
//  AC Cover
//
//  Created by Hari Karam Singh on 17/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "AC_CoverEmblemView.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _MAX_SHADOW_SIZE = 30;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverEmblemView
{
    UIImage *_emblemImg;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)newCoverEmblemView
{
    // Load the emblem image first to determine the size the view needs to be
    // Shadow can go L/R/B but not above
    UIImage *emblem = [UIImage imageNamed:@"cover_emblem"];
    NSParameterAssert(emblem);
    CGSize frameSize = CGSizeMake(emblem.size.width + 2 * _MAX_SHADOW_SIZE,
                                  emblem.size.height + 1 * _MAX_SHADOW_SIZE);
    CGRect f = {0, 0, frameSize};
    AC_CoverEmblemView *me = [[AC_CoverEmblemView alloc] initWithFrame:f];
    if (me) {
        me->_emblemImg = emblem;
        return me;
    }
    return nil;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@end
