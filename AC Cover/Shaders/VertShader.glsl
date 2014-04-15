//
//  Shader.vsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

attribute vec4 a_position;
attribute vec3 a_normal;
attribute vec2 a_texcoord;

varying highp vec2 v_texcoord;


// Used to simulate blade retraction
uniform mediump float modelHScale;
uniform mediump float texYOffset;

// Transform Matrices
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;
uniform mat4 projectionMatrix;


void main()
{
    v_texcoord = vec2(a_texcoord.x, clamp(a_texcoord.y + texYOffset, 0.0, 1.0));
    
    // Scale the height as per the retraction coefficient.  Note this only works as-is because the model base is on y=0.
    vec4 newPos = a_position;
    newPos.y *= modelHScale;
    
    gl_Position = projectionMatrix * modelViewMatrix * newPos;
}
