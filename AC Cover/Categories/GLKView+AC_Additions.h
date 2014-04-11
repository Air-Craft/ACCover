//
//  GLKView+AC_Additions.h
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface GLKView (AC_Additions)

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;

- (BOOL)linkProgram:(GLuint)prog;

- (BOOL)validateProgram:(GLuint)prog;

@end
