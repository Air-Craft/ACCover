//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
