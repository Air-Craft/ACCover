//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

/*
OPTIMISATIONS:
- Specular to use exp=1 for pow
- MVP pre-mult (low priority)
- singular hybrid lighting model
- manual vignette plus lighting only on edges
- try lowering precisions
 
 
ATTACK PLAN:
- material colour = 0.5
-
 
*/
precision mediump float;

varying mediump vec2 v_texcoord;
varying mediump vec4 v_position;

uniform sampler2D shapeTex;
uniform sampler2D normTex;

uniform mediump mat4 V, P;
uniform mediump mat4 V_norm;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Lighting and materials
/////////////////////////////////////////////////////////////////////////

struct LightSource
{
    mediump vec4 position;
    mediump vec4 diffuse;
    mediump vec4 specular;
    float constantAttenuation, linearAttenuation, quadraticAttenuation;
    float spotCutoff, spotExponent;
    vec3 spotDirection;
};
const LightSource light0 = LightSource(
    vec4(0.8,  2.2, -1.8, 1.0),
    vec4(vec3(0.8), 1.0),
    vec4(vec3(1.0), 1.0),
    0.0, 0.3, 0.1,
    30.0, 1.0,
    vec3(-0.2, -1.0, 0.0)
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
                              vec3(0.2),
                              vec4(vec3(0.9), 1.0),
                              vec4(vec3(0.5), 1.0),
                              vec4(vec3(0.0), 1.0),
                              3.0
                              );
const Material bladeBevel = Material(
                               vec3(0.0),
                               vec4(vec3(0.0), 1.0),
                               vec4(vec3(0.0), 1.0),
                               vec4(vec3(1.0), 1.0),
                               3.0
                               );

const float SURFACE_TEX_MULT = 0.4;  // Mix multiplier for shapeTex





/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


void main()
{
    // Sample the shape tex
    vec4 shapeTexColor = texture2D(shapeTex, v_texcoord);
    
    
    // Get the normal from the tex map and convert to View coords
    vec4 encodedNormal = texture2D(normTex, v_texcoord);
    vec3 localNormal = 2.0 * encodedNormal.rgb - vec3(1.0);
    vec3 normalDirection = normalize(vec3(V_norm*vec4(localNormal, 1.0)));

    // Derive a coefficient used to separate out the beveled edge (fuzzily) for colouring/lighting techniques
    //    float bevel = length(vec3(shapeTex)) *  shapeTex.a;
    // Only the bevel has x/y components.  first coeff is jsut to get it up near one
    float bevel = 1.3*length(vec2(localNormal));

    
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
     {
        vec3 positionToLightSource = vec3(light0.position - v_position);
        dist = length(positionToLightSource);
        lightDirection = normalize(positionToLightSource);
        attenuation = 1.0 / (light0.constantAttenuation
                             + light0.linearAttenuation * dist
                             + light0.quadraticAttenuation * dist * dist);
        
        if (light0.spotCutoff <= 90.0) // spotlight?
        {
            float clampedCosine = max(0.0, dot(-lightDirection, light0.spotDirection));
            if (clampedCosine < cos(radians(light0.spotCutoff))) // outside of spotlight cone?
            {
                attenuation = 0.0;
            }
            else
            {
                attenuation = attenuation * pow(clampedCosine, light0.spotExponent);
            }
        }
    }
    
    /////////////////////////////////////////
    // LIGHTING COEFS
    /////////////////////////////////////////
    
    vec3 outColor;
    
    if (bevel > 0.01) {
        
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
        
        vec3 texMult = (SURFACE_TEX_MULT * (vec3(shapeTexColor) - 0.5) + 0.5);
        outColor = (texMult * bladeSurface.color) + (ambientLighting + diffuseReflection + specularReflection);

    }
    
    
    /////////////////////////////////////////
    // OUTPUT
    /////////////////////////////////////////

    
//                        + bevel * bladeMaterial.bevelColor;
    
    gl_FragColor = vec4(outColor, shapeTexColor.a);
}
