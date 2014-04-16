//
//  Shader.fsh
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

precision mediump float;

varying mediump vec2 v_texcoord;
varying mediump vec4 v_position;

uniform sampler2D shapeTex;
uniform sampler2D normTex;

uniform mediump mat4 V, P;
uniform mediump mat3 V_norm;


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
    vec4(0.0,  1.2, -1, 1.0),
    vec4(1.0,  1.0,  1.0, 1.0),
    vec4(1.0,  1.0,  1.0, 1.0),
    0.0, 0.3, 0.1,
    180.0, 0.0,
    vec3(0.0, 0.0, 0.0)
);

vec4 sceneAmbient = vec4(0.2, 0.2, 0.2, 1.0);

struct Material
{
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
};
Material frontMaterial = Material(
                                  vec4(0.2, 0.2, 0.2, 1.0),
                                  vec4(0.3, 0.3, 0.3, 1.0),
                                  vec4(0.870, 0.801, 0.756, 0.5),
                                  50.0
                                  );




/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////


void main()
{
    // Get the normal and transform it through VP
    vec4 encodedNormal = texture2D(normTex, v_texcoord);
    vec3 localNormal = 2.0 * encodedNormal.rgb - vec3(1.0);
    vec3 normalDirection = normalize(V_norm*localNormal);
    
//    vec3 viewDirection = normalize(vec3(V_norm * vec4(0.0, 0.0, 0.0, 1.0) - v_position));
    vec3 viewDirection = normalize(vec3(vec4(0.0, 0.0, 0.0, 1.0) - v_position));
    vec3 lightDirection;
    float dist;
    float attenuation;
    
    if (0.0 == light0.position.w) // uni-directional light? (e.g. sun)
    {
        attenuation = 1.0; // no attenuation
        lightDirection = normalize(vec3(light0.position));
    }
    else // point light or spotlight (or other kind of light)
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
    
    vec3 ambientLighting = vec3(sceneAmbient) * vec3(frontMaterial.ambient);
    
    vec3 diffuseReflection = attenuation
                                * vec3(light0.diffuse) * vec3(frontMaterial.diffuse)
    * max(0.0, dot(normalDirection, lightDirection));
    
    vec3 specularReflection;
    if (dot(normalDirection, lightDirection) < 0.0) // light source on the wrong side?
    {
        specularReflection = vec3(0.0, 0.0, 0.0); // no specular reflection
    }
    else // light source on the right side
    {
        specularReflection = attenuation * vec3(light0.specular) * vec3(frontMaterial.specular)
        * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), frontMaterial.shininess);
    }
    
    // Multiply lighting by the shape texture
    gl_FragColor = texture2D(shapeTex, v_texcoord) * vec4(diffuseReflection, 1.0);
    
    
    
//    gl_FragColor = texture2D(shapeTex, v_texcoord) * vec4(ambientLighting + diffuseReflection + specularReflection, 1.0);
}
