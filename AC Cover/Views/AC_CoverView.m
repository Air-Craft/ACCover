//
//  AC_CoverView.m
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "AC_CoverView.h"
#import "GLKView+AC_Additions.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark - Calibration Extras
/////////////////////////////////////////////////////////////////////////

#ifdef AC_CALIBRATE

static NSMutableDictionary *_dbgUniformsDict;

#endif


/////////////////////////////////////////////////////////////////////////
#pragma mark - GL Data & Types
/////////////////////////////////////////////////////////////////////////

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//---------------------------------------------------------------------

//DBG
//static const GLfloat DBG_RETRACT_F = 0.0;
//static const GLfloat BLADE_SEPARATION = M_PI_2;
//static const GLfloat BLADE_ROTATION_OFFSET = 0.0;
//static const NSUInteger BLADE_CNT = 2.0;
//static const GLfloat BLADE_MAX_ROTATION = 2*M_PI;

// REAL
static const GLfloat DBG_RETRACT_F = 1.0;
static const GLfloat BLADE_SEPARATION = 30.f * M_PI / 180.f;
static const GLfloat BLADE_ROTATION_OFFSET = M_PI;
static const NSUInteger BLADE_CNT = 2.0f * M_PI / BLADE_SEPARATION + 1;
static const GLfloat BLADE_MAX_ROTATION = 60. * M_PI / 180.f;


static const GLfloat BLADE_TILT = 0.f * M_PI / 180.0f;
static const GLfloat BLADE_Z_OFFSET = -0.001;


static const GLfloat W = 0.644;     // reflect texture image dimentions / 1000
static const GLfloat H = 1.014;
static const GLfloat Z = -2;

//---------------------------------------------------------------------

// Uniform index.
enum
{
    M,      // Model-view-projection matrices
    V,
    P,
    V_norm,
    tex_color,
    tex_specular,
    tex_normal,
    tex_displacement,
    u_texYOffset,
    u_lightOffsetX,
    u_lightOffsetY,
    NUM_UNIFORMS
};
GLint _uniforms[NUM_UNIFORMS];



GLfloat _glCubeVertexData[48] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,    texU, texV
    W/2,  H, 0,      1, 1,
    -W/2, H, 0,      0, 1,
    W/2,  0, 0,      1, 0,
    W/2,  0, 0,      1, 0,
    -W/2, H, 0,      0, 1,
    -W/2, 0, 0,      0, 0
};


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverView
{
    GLuint _program;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKMatrix4 _viewMatrixBase;
    
    GLKTextureInfo *_bladeTexColor;
    GLKTextureInfo *_bladeTexNormal;
    GLKTextureInfo *_bladeTexSpecular;
    GLKTextureInfo *_bladeTexDisplacement;
    
    CMMotionManager *_motionManager;
    CMQuaternion _initRotation;
    BOOL _hasInitRotation;
    
    CADisplayLink *_updateTimer;
    
    // Animation related
    GLfloat _globalRotation;        // The amount all blades are rotated
    GLfloat _globalRetraction;      // Used to shrink H the GL rects to simulate retracting into the centre
    
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (void)setupWithMotionManager:(CMMotionManager *)motionManger
{
#ifdef AC_CALIBRATE
    _dbgUniformsDict = [@{@"u_attnConst": @0,
                       @"u_attnLinear": @0,
                       @"u_attnQuad": @0,
                       @"u_light0Pos": @0,
                       @"u_edgeFaceSplitFactor": @0,
                       @"u_diffuseIntensity": @0,
                       @"u_specularIntensity": @0,
                       @"u_shininess": @0
                       } mutableCopy];
#endif
    
    
    _globalRotation = 0;
    _globalRetraction = 0;
    
    
    /////////////////////////////////////////
    // CORE MOTION
    /////////////////////////////////////////
    
    _motionManager = motionManger;
    // too soon: _initRotation = motionManger.deviceMotion.attitude.quaternion;
    
    
    /////////////////////////////////////////
    // CONTEXT SETUP
    /////////////////////////////////////////
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        [NSException raise:NSGenericException format:@"Couldn't create GL Context!"];
    }
    [EAGLContext setCurrentContext:self.context];
    
    // Flags
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.drawableMultisample = GLKViewDrawableMultisampleNone;
    
    /////////////////////////////////////////
    // LIGHTING & TRANFORMS SETUP
    /////////////////////////////////////////

    // Default to shifting the model back a bit as to be visible in the viewport created by projectionMatrix
    _viewMatrixBase = GLKMatrix4MakeTranslation(0, 0, Z);
    
    
    /////////////////////////////////////////
    // DATA & BUFFERS
    /////////////////////////////////////////
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    {
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(_glCubeVertexData), _glCubeVertexData, GL_STATIC_DRAW);
        
        // Set position data
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, BUFFER_OFFSET(sizeof(GLfloat)*3));
    }
    glBindVertexArrayOES(0);
    
    
    /////////////////////////////////////////
    // SHADERS
    /////////////////////////////////////////

    [self _loadShaders];
    
    
    /////////////////////////////////////////
    // TEXTURES
    /////////////////////////////////////////
    
    NSError *err;
    NSString *f = [[NSBundle mainBundle] pathForResource:@"tex-blade-color" ofType:@"png"];
    _bladeTexColor = [GLKTextureLoader
                      textureWithContentsOfFile:f
                      options:@{
                                GLKTextureLoaderOriginBottomLeft: @YES,
                                GLKTextureLoaderApplyPremultiplication: @NO
                                }
                      error:&err];

    if (!_bladeTexColor) {
        [NSException raise:NSGenericException format:@"Error loading shape texture: %@", err];
    }
    
    // Normal map
    f = [[NSBundle mainBundle] pathForResource:@"tex-blade-norm" ofType:@"png"];
    _bladeTexNormal = [GLKTextureLoader
                       textureWithContentsOfFile:f
                       options:@{
                                 GLKTextureLoaderOriginBottomLeft: @YES,
                                 GLKTextureLoaderApplyPremultiplication: @YES
                                 }
                       error:&err];
    
    if (!_bladeTexNormal) {
        [NSException raise:NSGenericException format:@"Error loading normal map texture: %@", err];
    }
    
    
    f = [[NSBundle mainBundle] pathForResource:@"tex-blade-spec" ofType:@"png"];
    _bladeTexSpecular = [GLKTextureLoader
                         textureWithContentsOfFile:f
                         options:@{
                                   GLKTextureLoaderOriginBottomLeft: @YES,
                                   GLKTextureLoaderApplyPremultiplication: @NO
                                   }
                         error:&err];
    
    f = [[NSBundle mainBundle] pathForResource:@"tex-blade-disp" ofType:@"png"];
    _bladeTexDisplacement = [GLKTextureLoader
                             textureWithContentsOfFile:f
                             options:@{
                                       GLKTextureLoaderOriginBottomLeft: @YES,
                                       GLKTextureLoaderApplyPremultiplication: @NO
                                       }
                             error:&err];
    
    if (!_bladeTexDisplacement) {
        [NSException raise:NSGenericException format:@"Error loading shape texture: %@", err];
    }
    
    
    /////////////////////////////////////////
    // UNIFORMS (that dont change)
    /////////////////////////////////////////
    glUseProgram(_program);
    {
        // @TODO move to setup
        float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
        GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(43.0f), aspect, 1.732f, 100.f);

        glUniformMatrix4fv(_uniforms[P], 1, 0, projectionMatrix.m);

        // Color tex
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(_bladeTexColor.target, _bladeTexColor.name);
        glUniform1i(_uniforms[tex_color], 0);
        
        // Norm tex
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(_bladeTexNormal.target, _bladeTexNormal.name);
        glUniform1i(_uniforms[tex_normal], 1);

        // Specular tex
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(_bladeTexSpecular.target, _bladeTexSpecular.name);
        glUniform1i(_uniforms[tex_specular], 2);

        // Displacement tex
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(_bladeTexDisplacement.target, _bladeTexDisplacement.name);
        glUniform1i(_uniforms[tex_displacement], 3);
    }
    glUseProgram(0);
    
    /////////////////////////////////////////
    // UPDATE TIMER (TEMP???)
    /////////////////////////////////////////
    _updateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(_update:)];
    [_updateTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    
    // Clear the context to be polite
    [EAGLContext setCurrentContext:nil];
}

//---------------------------------------------------------------------

- (void)dealloc
{
    [_updateTimer invalidate];
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}


//---------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

- (void)setRetraction:(float)retraction
{
    _retraction = retraction;
    _globalRotation = -BLADE_MAX_ROTATION * _retraction;
    _globalRetraction = _retraction * DBG_RETRACT_F;
}

//---------------------------------------------------------------------

- (void)setUniform:(NSString *)theName withFloat:(float)theValue
{
    glUseProgram(_program);
    glUniform1f([_dbgUniformsDict[theName] intValue], theValue);
}

//---------------------------------------------------------------------

- (void)setUniform:(NSString *)theName withVec4:(GLKVector4)theValue
{
    glUseProgram(_program);
    glUniform4fv([_dbgUniformsDict[theName] intValue], 1, theValue.v);
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_update:(CADisplayLink *)sender
{
    goto skip;
    
    const float T = 8;    // Animation period, retract and expand cycle
    
    // Initialise time on first cycle
    static NSTimeInterval lastTime = -1.0;
    NSTimeInterval t;
    t = CACurrentMediaTime();
    if (lastTime < 0) {
        lastTime = t;
        return;
    }

    float wave = sinf(2.f*M_PI/T * t);
    wave = MAX((wave * wave) - 0.2, 0.0) * 1.25;
    _globalRotation = -BLADE_MAX_ROTATION * wave;
    _globalRetraction = wave;       // 0 = out, 1 = in
    
    
    lastTime = t;
    
skip:
    [self setNeedsDisplay];
}


//---------------------------------------------------------------------

- (void)drawRect:(CGRect)rect
{

    // @TODO Set context??  Hopefully not. Try to prevent dual GL contexts operating in order to save bandwidth
    
    glEnable (GL_BLEND);
//    glEnable(GL_DEPTH_TEST);
//    glEnable(GL_ALPHA_TEST);
//    glAlphaFunc(GL_GREATER, 0.01);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.08f, 0.08f, 0.08f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    glUseProgram(_program);
    
    
    /////////////////////////////////////////
    // GLOBAL UNIFORMS
    /////////////////////////////////////////
    
    
    // Lighting offset based on deviation from initial angular position
    CMQuaternion newRotation = _motionManager.deviceMotion.attitude.quaternion;

    // grab init rotation if first run
    if (!_hasInitRotation) {
        _initRotation = newRotation;
        _hasInitRotation = YES;
    }

    
    // rotation around X affects Y lighting position and vice versa
    CGPoint lightingOffset = {
//        (newRotation.y - 0.0) * 1.0/M_PI_4 * -2,
//        (newRotation.x - M_PI/6.0) * 1.0/M_PI_4 * 2,
        (newRotation.y - _initRotation.y) * 1.0/M_PI_4 * -0.8,
        (newRotation.x - _initRotation.x) * 1.0/M_PI_4 * 1.5,
    };

    glUniform1f(_uniforms[u_lightOffsetX], lightingOffset.x);
    glUniform1f(_uniforms[u_lightOffsetY], lightingOffset.y);
    
    
    /////////////////////////////////////////
    // DRAW BLADES
    /////////////////////////////////////////

    // Derive/set uniforms for blade retraction
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
//    GLKMatrix4MakeScale(1, 1 - _globalRetraction, 1);
    // assigned below...
    
    // Texture retraction, inverse mirrors the height scaling
    float newH = H * (1 - _globalRetraction);
    float yOffsetNormed = (H - newH) / H;
    glUniform1f(_uniforms[u_texYOffset], yOffsetNormed);

    
    
    // For each blade...
    for (int i=0; i<BLADE_CNT; i++) {
        
        // M MATRIX (REDUNDANT!)
        // Add a progessive Z offset for each
        modelMatrix = GLKMatrix4Translate(modelMatrix, 0, 0, BLADE_Z_OFFSET * i);
        glUniformMatrix4fv(_uniforms[M], 1, 0, modelMatrix.m);
        
        // V MATRIX
        // First shift the blades to make them retract.  An X shift is needed to ensure the edges stay hidden.  This is intrinsically linked to the first line of the frag shader glsl.  A tiny Z shift ensures no unintended depth artifact when the blades overlap
        // Rotation is then applied to position the blade in the view
        GLfloat delY = -H * _globalRetraction;
        GLfloat delX = MAX(0.0, _globalRetraction - 0.4) * -0.3;
        GLfloat delZ = i * BLADE_Z_OFFSET;
        GLfloat rot = i * BLADE_SEPARATION + _globalRotation + BLADE_ROTATION_OFFSET;
        
        GLKMatrix4 vMatrix = _viewMatrixBase;
        vMatrix = GLKMatrix4Rotate(vMatrix, BLADE_TILT, 0, 1.0, 0);
        vMatrix = GLKMatrix4Rotate(vMatrix, rot, 0, 0, 1.0);
        vMatrix = GLKMatrix4Translate(vMatrix, delX, delY, delZ);
        glUniformMatrix4fv(_uniforms[V], 1, 0, vMatrix.m);

        
        /////////////////////////////////////////
        // NORM MATRIX
        /////////////////////////////////////////
        
//        GLKMatrix3 normMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(vMatrix), NULL);
//        glUniformMatrix3fv(_uniforms[V_norm], 1, 0, normMatrix.m);
        GLKMatrix4 normMatrix = GLKMatrix4InvertAndTranspose(vMatrix, NULL);
        glUniformMatrix4fv(_uniforms[V_norm], 1, 0, normMatrix.m);
       
        glDrawArrays(GL_TRIANGLES, 0, 36);
    }
    
}


//---------------------------------------------------------------------

/** @todo Proper exception types */
- (void)_loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"VertShader" ofType:@"glsl"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        [NSException raise:NSGenericException format:@"Failed to compile vertex shader"];
        return;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"FragShader" ofType:@"glsl"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        [NSException raise:NSGenericException format:@"Failed to compile fragment shader"];
        return;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "a_position");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "a_texcoord");
    
    // Link program.
    if (![self linkProgram:_program]) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        [NSException raise:NSGenericException format:@"Failed to link program: %d", _program];
        return;
    }

    // Get uniform locations.
    _uniforms[M] = glGetUniformLocation(_program, "M");
    _uniforms[V] = glGetUniformLocation(_program, "V");
    _uniforms[P] = glGetUniformLocation(_program, "P");
    _uniforms[V_norm] = glGetUniformLocation(_program, "V_norm");
    _uniforms[tex_color] = glGetUniformLocation(_program, "tex_color");
    _uniforms[tex_specular] = glGetUniformLocation(_program, "tex_specular");
    _uniforms[tex_normal] = glGetUniformLocation(_program, "tex_normal");
    _uniforms[tex_displacement] = glGetUniformLocation(_program, "tex_displacement");
    _uniforms[u_texYOffset] = glGetUniformLocation(_program, "u_texYOffset");
    _uniforms[u_lightOffsetX] = glGetUniformLocation(_program, "u_lightOffsetX");
    _uniforms[u_lightOffsetY] = glGetUniformLocation(_program, "u_lightOffsetY");
//    _uniforms[] = glGetUniformLocation(_program, "");
    
    
#ifdef AC_CALIBRATE
    // Get the debug uniforms
    [_dbgUniformsDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        _dbgUniformsDict[key] = @(glGetUniformLocation(_program, key.UTF8String));
    }];
#endif
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
}





@end
