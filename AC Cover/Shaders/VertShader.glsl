//
//  Shader.vsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//
precision mediump float;

attribute vec4 a_position;
attribute vec2 a_texcoord;

varying highp vec2 v_texcoord;
varying mediump vec4 v_position;

// Used to simulate blade retraction
uniform mediump float texYOffset;

// Transform Matrices
uniform mediump mat4 M, V, P;


void main()
{
    v_texcoord = a_texcoord;
    
    // Scale the height as per the retraction coefficient.  Note this only works as-is because the model base is on y=0.
    
    // Frag's shader needs the model xformed position
    v_position = V * a_position;
    
    gl_Position = P * V * a_position;
}
