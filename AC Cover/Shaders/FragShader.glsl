//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#define AC_CALIBRATE

precision lowp float;

const lowp float SQRT_3 = 1.73205080757;
const lowp float INV_SQRT_3 = 1.0/SQRT_3;


varying mediump vec2 v_texcoord;
varying mediump vec4 v_position;

uniform sampler2D tex_color;
uniform sampler2D tex_specular;
uniform sampler2D tex_normal;
uniform sampler2D tex_displacement;

// Used to cutoff the tex drawing below the screen centrepoint
uniform mediump float u_texYOffset;

// Offsets for main light position (linked to device motion)
uniform float u_lightOffsetX;
uniform float u_lightOffsetY;

uniform mediump mat4 V, P;
uniform mediump mat4 V_norm;


#ifdef AC_CALIBRATE
uniform float u_attnConst;
uniform float u_attnLinear;
uniform float u_attnQuad;
uniform vec4 u_light0Pos;
uniform float u_light0Intensity;
uniform vec4 u_light1Pos;
uniform float u_light1Intensity;

uniform float u_edgeFaceSplitFactor;
uniform float u_diffuseIntensity;     // face only
uniform float u_specularIntensity;    // shared multipler for spec map reading
uniform float u_shininess;

#else

const float u_attnConst = 0.0;
const float u_attnLinear = 0.3;
const float u_attnQuad = 0.1;
const vec4 u_light0Pos = vec4(1.0, 3.0, -1.0, 0.0);
//const float u_light0Intensity;
//const vec4 u_light1Pos;
//const float u_light1Intensity;

const float u_edgeFaceSplitFactor = 20.0;
const float u_diffuseIntensity = 1.0;     // face only
const float u_specularIntensity = 1.0;    // shared multipler for spec map reading
const float u_shininess = 3.0;

#endif

const vec4 u_colorMix = vec4(vec3(1.0), 1.0);
const float u_displacementScale = 0.0;//0.8;

/////////////////////////////////////////////////////////////////////////
#pragma mark - Lighting and materials
/////////////////////////////////////////////////////////////////////////

// Even though the perspective tranform has an impled origin for the camera, we can fake it here to get a better reflection angle for the bevels.
const vec3 CAMERA_POS = vec3(0.0, 0.0, 3.0);

// Light colours.
// Not really alpha=0 but they are added to the base color so we want alpha unaffected
//const vec4 DIFFUSE_COLOR = vec4(0.999, 0.987, 0.9, 0.0);
//const vec4 SPECULAR_COLOR = vec4(0.999, 0.987, 0.9, 0.0);
const vec4 grey = vec4(0.4, 0.4, 0.4, 0.0);
const vec4 paleYellow = vec4(0.97, 0.96, 0.81, 0.0);
const vec4 paleBlue = vec4(0.82, 0.98, 0.97, 0.0);
const vec4 darkBlue = vec4(0.34, 0.40, 0.40, 0.0);
const vec4 darkYellow = vec4(0.1, 0.1, 0.08, 0.0);
const vec4 blueGreen = vec4(0.519, 0.997, 0.7, 0.0);
const vec4 DIFFUSE_COLOR = grey;
const vec4 SPECULAR_COLOR = paleYellow;



/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


void main()
{
    
    /////////////////////////////////////////
    // TEXTURE MAPS & LIGHTING COEFFS
    /////////////////////////////////////////
    
    // Make the retraction by offsetting and clamping the tex drawing. Ensures that it only renders "above" (wrt blade rotation) the screen centrepoint
    // retraction crop blend: 1 means pure crop from the top inward, 0 = pure retraction (you see the tex top rim).
    const float retrCropBlend = 0.5;
    vec2 texcoord = (v_texcoord - vec2(0.0, u_texYOffset*retrCropBlend)) * step(u_texYOffset, v_texcoord.y);
    
    // Base Color (and shape via alpha)
    vec4 baseColor = texture2D(tex_color, texcoord);
    
    // Normal: Get from the tex map and convert to View coords
    vec4 encodedNormal = texture2D(tex_normal, texcoord);
    vec3 localNormal = 2.0 * encodedNormal.rgb - vec3(1.0);
    vec3 normalDirection = normalize(vec3(V_norm*vec4(localNormal, 1.0)));

    // Displacement
    const vec2 i = vec2(1.0, 0.0);
    vec4 encodedDisp = texture2D(tex_displacement, texcoord);
    float disp = mix(-0.5*u_displacementScale, 0.5*u_displacementScale, length(encodedDisp.rgb));
    vec4 texpos = v_position - disp * i.yyxy;
    
    
    // Face factor
    // = the color intensity * scale amount to split the full black edge from the dark face
    float faceFactor = min(1.0, length(baseColor.rgb) * u_edgeFaceSplitFactor);
    
    // Diffuse factor
    float diffuseFactor = faceFactor * u_diffuseIntensity;  // face only
    
    // Specular factor (intensity)
    vec4 encodedSpec = texture2D(tex_specular, texcoord);
    float specularFactor = length(encodedSpec.xyz) * INV_SQRT_3 * u_specularIntensity * (1.0 - faceFactor);
    
    // Full shininess for edge, almost none for face hopefully
    float shinyFactor = max(0.0, 1.0 - faceFactor) * u_shininess;

//    vec3 viewDirection = normalize(vec3(V_norm * vec4(0.0, 0.0, 0.0, 1.0) - texpos));
    // Camera's V transform is nil so leave it out.
    vec3 viewDirection = normalize(CAMERA_POS - vec3(texpos));
    
    
    /////////////////////////////////////////
    // ATTENUATION
    /////////////////////////////////////////
    
    vec3 lightDirection;
    float lightDistance;
    float attenuation;
    vec4 lightPos = u_light0Pos + vec4(u_lightOffsetX, u_lightOffsetY, 0.0, 0.0);
    
//    if (0.0 == light0.position.w) // uni-directional light? (e.g. sun)
//    {
//        attenuation = 1.0; // no attenuation
//        lightDirection = normalize(vec3(light0.position));
//    }
//    else // point light or spotlight (or other kind of light)
//     {
        vec3 positionToLightSource = vec3(lightPos - texpos);
        lightDistance = length(positionToLightSource);
        lightDirection = normalize(positionToLightSource);
        attenuation = 1.0 / (u_attnConst   // constant
                             + u_attnLinear * lightDistance
                             + u_attnQuad * lightDistance * lightDistance);
//    }

    
    /////////////////////////////////////////
    // DIFFUSE
    /////////////////////////////////////////
    
    float angleAttenDiff = max(0.0, dot(normalDirection, lightDirection));
    vec4 outDiffuse = attenuation * diffuseFactor * angleAttenDiff * DIFFUSE_COLOR;
    
    
    /////////////////////////////////////////
    // SPECULAR
    /////////////////////////////////////////
    
    float angleAttenSpec = pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), shinyFactor);
    
    vec4 outSpecular =
        attenuation * 1.0 * specularFactor * angleAttenSpec
         * SPECULAR_COLOR;
    
    
//    vec3 texMult = (SURFACE_TEX_MULT * (vec3(baseColor) - 0.5) + 0.5);
//    outColor = (texMult * bladeSurface.color) + (ambientLighting + diffuseReflection + specularReflection);
    
    
    /////////////////////////////////////////
    // OUTPUT
    /////////////////////////////////////////

    gl_FragColor = baseColor * u_colorMix + outDiffuse + outSpecular;
    
//    gl_FragColor = vec4(vec3(angleAtten), 1.0);
//    gl_FragColor = vec4(normalDirection.yyy+0.5, 1.0);
//    gl_FragColor = vec4(vec3(angleAtten),baseColor.a);
//    gl_FragColor = vec4(vec3(specularFactor), 1.0);
//    gl_FragColor = vec4(vec3(texpos.z * -0.25), 1.0);
//    gl_FragColor = vec4(abs(positionToLightSource.r), abs(positionToLightSource.g), abs(positionToLightSource.b), 1.0);
//    gl_FragColor = vec4(1.0, 1.0, 1.0, -disp);
//    gl_FragColor = vec4(vec3(faceFactor), 1.0);
    
}
