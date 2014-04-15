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
#pragma mark - GL Data & Types
/////////////////////////////////////////////////////////////////////////

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//---------------------------------------------------------------------

static const GLfloat BLADE_SEPARATION = 30.f * M_PI / 180.f;
static const NSUInteger BLADE_CNT = 2.0f * M_PI / BLADE_SEPARATION + 1;
static const GLfloat BLADE_TILT = 0.f * M_PI / 180.0f;
static const GLfloat BLADE_MAX_ROTATION = 60. * M_PI / 180.f;

static const GLfloat W = 0.719;     // reflect texture image dimentions / 1000
static const GLfloat H = 1.024;
static const GLfloat Z = -2;

//---------------------------------------------------------------------

// Uniform index.
enum
{
    projectionMatrix,
    modelViewMatrix,
    normalMatrix,
    shapeTex,
    bumpTex,
    modelHScale,
    texYOffset,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];



GLfloat _glCubeVertexData[48] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,  texU, texV
    W/2,  H, 0,      0.0f, 0.0f, 1.0f,      1, 1,
    -W/2, H, 0,      0.0f, 0.0f, 1.0f,      0, 1,
    W/2,  0, 0,      0.0f, 0.0f, 1.0f,      1, 0,
    W/2,  0, 0,      0.0f, 0.0f, 1.0f,      1, 0,
    -W/2, H, 0,      0.0f, 0.0f, 1.0f,      0, 1,
    -W/2, 0, 0,      0.0f, 0.0f, 1.0f,      0, 0
};


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverView
{
    GLuint _program;
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix3 _normalMatrix;
    GLKTextureInfo *_bladeShapeTex;
    GLKTextureInfo *_bladeBumpTex;
    
    
    CADisplayLink *_updateTimer;
    
    // Animation related
    GLfloat _globalRotation;        // The amount all blades are rotated
    GLfloat _globalRetraction;      // Used to shrink H the GL rects to simulate retracting into the centre
    
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

- (void)setup
{
    _globalRotation = 0;
    _globalRetraction = 0;
    
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

    
    /////////////////////////////////////////
    // LIGHTING & TRANFORMS SETUP
    /////////////////////////////////////////

    float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(53.0f), aspect, 1.732f, 100.f);
    _modelViewMatrix = GLKMatrix4MakeTranslation(0, 0, Z);
    
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
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, BUFFER_OFFSET(sizeof(GLfloat)*3));
        
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, BUFFER_OFFSET(sizeof(GLfloat)*6));
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
    NSString *f = [[NSBundle mainBundle] pathForResource:@"tex-blade-shape" ofType:@"png"];
    _bladeShapeTex = [GLKTextureLoader
                      textureWithContentsOfFile:f
                      options:@{
                                GLKTextureLoaderOriginBottomLeft: @YES,
                                GLKTextureLoaderApplyPremultiplication: @NO
                                }
                      error:&err];

    if (!_bladeShapeTex) {
        [NSException raise:NSGenericException format:@"Error loading texture: %@", err];
    }
    
    
    /////////////////////////////////////////
    // UNIFORMS (that dont change)
    /////////////////////////////////////////
    glUseProgram(_program);
    {
        // @TODO move to setup
        glUniformMatrix4fv(uniforms[projectionMatrix], 1, 0, _projectionMatrix.m);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(_bladeShapeTex.target, _bladeShapeTex.name);
        glEnable(_bladeShapeTex.target);
        glUniform1i(uniforms[shapeTex], 0);
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
#pragma mark - Additional Privates
/////////////////////////////////////////////////////////////////////////

- (void)_update:(CADisplayLink *)sender
{
    const float T = 16;    // Animation period, retract and expand cycle
    
    // Initialise time on first cycle
    static NSTimeInterval lastTime = -1.0;
    NSTimeInterval t;
    t = CACurrentMediaTime();
    if (lastTime < 0) {
        lastTime = t;
        return;
    }
    NSTimeInterval delta_t = t - lastTime;

    float wave = sinf(2.f*M_PI/T * t);
    wave = MAX((wave * wave) - 0.2, 0.0);
    _globalRotation = BLADE_MAX_ROTATION * wave;
    _globalRetraction = wave;       // 0 = out, 1 = in
    
    
    goto skip;
    
//    float aspect = fabsf(self.bounds.size.width / self.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
//    _effect.transform.projectionMatrix = projectionMatrix;
    
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
//    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
//    
//    // Compute the model view matrix for the object rendered with GLKit
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    
//    _effect.transform.modelviewMatrix = modelViewMatrix;
//    
//    // Compute the model view matrix for the object rendered with ES2
//    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    
//    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
//    
//    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
//    
//    _rotation += timeSinceLastUpdate * 0.5f;
    
    lastTime = t;
    
skip:
    [self setNeedsDisplay];
}


//---------------------------------------------------------------------

- (void)drawRect:(CGRect)rect
{

    // @TODO Set context??  Hopefully not. Try to prevent dual GL contexts operating in order to save bandwidth
    
//    glEnable(GL_DEPTH_TEST);
    glEnable (GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.05f, 0.05f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    glUseProgram(_program);
    
    
    // Derive/set uniforms for blade retraction
    glUniform1f(uniforms[modelHScale], 1 - _globalRetraction);
    
    // Texture is a little tricker.
    float newH = H * (1 - _globalRetraction);
    float yOffsetNormed = (H - newH) / H;
    glUniform1f(uniforms[texYOffset], yOffsetNormed);

    
    
    
    // For each blade...
    for (int i=0; i<BLADE_CNT; i++) {
        
        /////////////////////////////////////////
        // MV MATRIX
        /////////////////////////////////////////
        // ...Rotate and tilt the model (via the MV matrix) and render once for each blade
        
        GLKMatrix4 mvMatrix = GLKMatrix4Identity;
//        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, i * 0.01);
        mvMatrix = GLKMatrix4Rotate(_modelViewMatrix, BLADE_TILT, 0, 1.0, 0);
        mvMatrix = GLKMatrix4Rotate(mvMatrix, -i * BLADE_SEPARATION - _globalRotation, 0, 0, 1.0);
        glUniformMatrix4fv(uniforms[modelViewMatrix], 1, 0, mvMatrix.m);

        /////////////////////////////////////////
        // NORM MATRIX
        /////////////////////////////////////////
        _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mvMatrix), NULL);
        glUniformMatrix3fv(uniforms[normalMatrix], 1, 0, _normalMatrix.m);
        
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
    glBindAttribLocation(_program, GLKVertexAttribNormal, "a_normal");
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
    uniforms[modelViewMatrix] = glGetUniformLocation(_program, "modelViewMatrix");
    uniforms[projectionMatrix] = glGetUniformLocation(_program, "projectionMatrix");
    uniforms[normalMatrix] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[shapeTex] = glGetUniformLocation(_program, "shapeTex");
    uniforms[bumpTex] = glGetUniformLocation(_program, "bumpTex");
    uniforms[modelHScale] = glGetUniformLocation(_program, "modelHScale");
    uniforms[texYOffset] = glGetUniformLocation(_program, "texYOffset");
    
    
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
