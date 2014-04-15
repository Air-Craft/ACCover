//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//




varying mediump vec2 v_texcoord;


uniform sampler2D shapeTex;
uniform sampler2D normTex;


void main()
{
    mediump vec2 newTexcoord = v_texcoord;
//    newTexcoord.y = clamp(newTexcoord.y + texYOffset, 0.0, 1.0);
    gl_FragColor = texture2D(shapeTex, newTexcoord) * vec4(0.3, 0.3, 0.3, 1.0) + vec4(0.2);
}
