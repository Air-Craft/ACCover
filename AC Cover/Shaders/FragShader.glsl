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


precision mediump float;

varying mediump vec2 v_texcoord;
varying mediump vec4 v_position;

uniform sampler2D tex_color;
uniform sampler2D tex_specular;
uniform sampler2D tex_normal;

uniform mediump mat4 V, P;
uniform mediump mat4 V_norm;


#ifdef AC_CALIBRATE
uniform lowp vec3 u_light0Pos;
uniform lowp float u_light0Intensity;
uniform lowp vec3 u_light1Pos;
uniform lowp float u_light1Intensity;
uniform lowp float u_faceDiffIntensity;
uniform lowp float u_faceSpecIntensity;
uniform lowp float u_edgeDiffIntensity;
uniform lowp float u_edgeSpecIntensity;
#else
// define constants?
#endif


/////////////////////////////////////////////////////////////////////////
#pragma mark - Lighting and materials
/////////////////////////////////////////////////////////////////////////

struct LightSource
{
    mediump vec4 position;
    mediump vec4 diffuse;
    mediump vec4 specular;
    float constantAttenuation, linearAttenuation, quadraticAttenuation;
};
const LightSource light0 = LightSource(
    vec4(1.0, 3.0, -1.0, 1.0),
    vec4(vec3(0.05), 1.0),
    vec4(vec3(0.9), 1.0),
    0.0, 0.3, 0.1
);

// Even though the perspective tranform has an impled origin for the camera, we can fake it here to get a better reflection angle for the bevels.
const vec3 cameraPos = vec3(0.0, 0.0, 3.0);
const vec4 sceneAmbient = vec4(vec3(0.0), 1.0);

struct Material
{
    vec3 color;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;    // exp in pow(). 0 = none (ambient),
};
const Material bladeSurface = Material(
                              vec3(0.1),
                              vec4(vec3(0.1), 1.0),
                              vec4(vec3(1.0), 1.0),
                              vec4(vec3(0.0), 1.0),
                              3.0
                              );
const Material bladeBevel = Material(
                               vec3(0.0),
                               vec4(vec3(0.0), 1.0),
                               vec4(vec3(0.0), 1.0),
                               vec4(vec3(1.0), 1.0),
                               2.0
                               );

const float SURFACE_TEX_MULT = 0.4;  // Mix multiplier for shapeTex





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

    // Specular factor (intensity)
    vec4 encodedSpec = texture2D(tex_specular, v_texcoord);
    float specularFactor = length(encodedSpec.xyz) * INV_SQRT_3;
    
    // Diffuse factor (use the color scaled)
    // * scale amount to split the full black edge from the dark face
    float diffuseFactor = length(baseColor.xyz) * 10.0;
    
    
    
//    vec3 viewDirection = normalize(vec3(V_norm * vec4(0.0, 0.0, 0.0, 1.0) - v_position));
    // Camera's V transform is nil so leave it out.
    vec3 viewDirection = normalize(cameraPos - vec3(v_position));
    
    vec3 lightDirection;
    float dist;
    float attenuation;
    
    /////////////////////////////////////////
    // ATTENUATION
    /////////////////////////////////////////

//    if (0.0 == light0.position.w) // uni-directional light? (e.g. sun)
//    {
//        attenuation = 1.0; // no attenuation
//        lightDirection = normalize(vec3(light0.position));
//    }
//    else // point light or spotlight (or other kind of light)
//     {
        vec3 positionToLightSource = vec3(light0.position - v_position);
        dist = length(positionToLightSource);
        lightDirection = normalize(positionToLightSource);
        attenuation = 1.0 / (light0.constantAttenuation
                             + light0.linearAttenuation * dist
                             + light0.quadraticAttenuation * dist * dist);
//    }
    
    /////////////////////////////////////////
    // LIGHTING COEFS
    /////////////////////////////////////////
    
    vec3 outColor;
    
    if (diffuseFactor < 0.01) {
        
        vec3 ambientLighting = vec3(sceneAmbient) * vec3(bladeBevel.ambient);
        
        vec3 diffuseReflection = attenuation
        * vec3(light0.diffuse) * vec3(bladeBevel.diffuse)
        * max(0.0, dot(normalDirection, lightDirection));
        
        vec3 specularReflection;
        if (dot(normalDirection, lightDirection) < 0.0) // light source on the wrong side?
        {
            specularReflection = vec3(0.0, 0.0, 0.0); // no specular reflection
        }
        else // light source on the right side
        {
            specularReflection = attenuation * vec3(light0.specular) * vec3(bladeBevel.specular)
            * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), bladeBevel.shininess);
        }
        
        outColor = bladeBevel.color + (ambientLighting + diffuseReflection + specularReflection);
        
    } else {
        
        vec3 ambientLighting = vec3(sceneAmbient) * vec3(bladeSurface.ambient);
        
        vec3 diffuseReflection = attenuation
        * vec3(light0.diffuse) * vec3(bladeSurface.diffuse)
        * max(0.0, dot(normalDirection, lightDirection));
        
        vec3 specularReflection;
        if (dot(normalDirection, lightDirection) < 0.0) // light source on the wrong side?
        {
            specularReflection = vec3(0.0, 0.0, 0.0); // no specular reflection
        }
        else // light source on the right side
        {
            specularReflection = attenuation * vec3(light0.specular) * vec3(bladeSurface.specular)
            * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), bladeSurface.shininess);
        }
        
        vec3 texMult = (SURFACE_TEX_MULT * (vec3(baseColor) - 0.5) + 0.5);
        outColor = (texMult * bladeSurface.color) + (ambientLighting + diffuseReflection + specularReflection);

    }
    
    
    /////////////////////////////////////////
    // OUTPUT
    /////////////////////////////////////////

    
//                        + bevel * bladeMaterial.bevelColor;
    
    gl_FragColor = vec4(outColor, baseColor.a); // + vec4(1.0, 1.0, 1.0, 0.5);
}
