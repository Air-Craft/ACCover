//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

/*
OPTIMISATIONS:

 
 
ATTACK PLAN:
- material colour = 0.5
-
*/
#define AC_CALIBRATE


const lowp float SQRT_3 = 1.73205080757;
const lowp float INV_SQRT_3 = 1.0/SQRT_3;


precision lowp float;

varying mediump vec2 v_texcoord;
varying mediump vec4 v_position;

uniform sampler2D tex_color;
uniform sampler2D tex_specular;
uniform sampler2D tex_normal;

uniform mediump mat4 V, P;
uniform mediump mat4 V_norm;


#ifdef AC_CALIBRATE
uniform float u_attn_const = 0.0;
uniform float u_attn_linear = 0.3;
uniform float u_attn_quad = 0.1;
uniform vec3 u_light0Pos = vec3(;
uniform float u_light0Intensity;
uniform vec3 u_light1Pos;
uniform float u_light1Intensity;

uniform float u_edgeFaceSplitFactor = 10.0;
uniform float u_diffuseIntensity = 1.0;     // face only
uniform float u_specularIntensity = 1.0;    // shared multipler for spec map reading
uniform float u_shininess = 3.0;

#else
// define constants?
#endif


/////////////////////////////////////////////////////////////////////////
#pragma mark - Lighting and materials
/////////////////////////////////////////////////////////////////////////

// Even though the perspective tranform has an impled origin for the camera, we can fake it here to get a better reflection angle for the bevels.
const vec3 CAMERA_POS = vec3(0.0, 0.0, 3.0);
const vec4 DIFFUSE_COLOR = vec4(1.0, 1.0, 1.0, 0.0);    // Not really alpha=0 but they are added to the base color so we want alpha unaffected
const vec4 SPECULAR_COLOR = vec4(1.0, 1.0, 1.0, 0.0);


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


void main()
{
    // BASE COLOR
    // if edge, then specular (3 color?), no diffuse
    // if face then both
    
    // option 1: same lighting for all but with scaling factor for edge (based on spec map)
    // option 2: branching or mix'ing
    // lets try option 1 first
    
    // other options: REMEMBER we have alpha channels in the spec and norm maps to encode with!
    
    // Base Color (and shape via alpha)
    vec4 baseColor = texture2D(tex_color, v_texcoord);
    
    // Normal: Get from the tex map and convert to View coords
    vec4 encodedNormal = texture2D(tex_normal, v_texcoord);
    vec3 localNormal = 2.0 * encodedNormal.rgb - vec3(1.0);
    vec3 normalDirection = normalize(vec3(V_norm*vec4(localNormal, 1.0)));

    // Face factor
    // = the color intensity * scale amount to split the full black edge from the dark face
    float faceFactor = min(1.0, length(baseColor.rgb) * u_edgeFaceSplitFactor);
    
    // Diffuse factor
    float diffuseFactor = faceFactor * u_diffuseIntensity;  // face only
    
    // Specular factor (intensity)
    vec4 encodedSpec = texture2D(tex_specular, v_texcoord);
    float specularFactor = length(encodedSpec.xyz) * INV_SQRT_3 * u_specularIntensity;
    
    // Full shininess for edge, almost none for face hopefully
    float shinyFactor = max(0.0, 1.0 - diffuseFactor) * u_shininess;

//    vec3 viewDirection = normalize(vec3(V_norm * vec4(0.0, 0.0, 0.0, 1.0) - v_position));
    // Camera's V transform is nil so leave it out.
    vec3 viewDirection = normalize(CAMERA_POS - vec3(v_position));
    
    
    /////////////////////////////////////////
    // ATTENUATION
    /////////////////////////////////////////
    
    vec3 lightDirection;
    float lightDistance;
    float attenuation;
    
//    if (0.0 == light0.position.w) // uni-directional light? (e.g. sun)
//    {
//        attenuation = 1.0; // no attenuation
//        lightDirection = normalize(vec3(light0.position));
//    }
//    else // point light or spotlight (or other kind of light)
//     {
        vec3 positionToLightSource = vec3(u_light0Pos - v_position);
        lightDistance = length(positionToLightSource);
        lightDirection = normalize(positionToLightSource);
        attenuation = 1.0 / (u_attn_const   // constant
                             + u_attn_linear * lightDistance
                             + u_attn_quad * lightDistance * lightDistance);
//    }
    
    /////////////////////////////////////////
    // DIFFUSE
    /////////////////////////////////////////
    
    vec4 outDiffuse = attenuation * diffuseFactor * max(0.0, dot(normalDirection, lightDirection)) * DIFFUSE_COLOR;
    
    
    /////////////////////////////////////////
    // SPECULAR
    /////////////////////////////////////////
    
    vec4 outSpecular =
        attenuation * specularFactor *
        pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), shinyFactor) *SPECULAR_COLOR;
    
    
//    vec3 texMult = (SURFACE_TEX_MULT * (vec3(baseColor) - 0.5) + 0.5);
//    outColor = (texMult * bladeSurface.color) + (ambientLighting + diffuseReflection + specularReflection);
    
    
    /////////////////////////////////////////
    // OUTPUT
    /////////////////////////////////////////

    
//                        + bevel * bladeMaterial.bevelColor;
    gl_FragColor = baseColor + outDiffuse + outSpecular;
//    gl_FragColor = vec4(outColor, baseColor.a); // + vec4(1.0, 1.0, 1.0, 0.5);
}
