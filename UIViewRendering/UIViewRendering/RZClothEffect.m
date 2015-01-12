//
//  RZClothEffect.m
//
//  Created by Rob Visentin on 1/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.ES2;
@import QuartzCore;
#import "RZClothEffect.h"

static NSString* const kRZClothVSH = RZ_SHADER_SRC(
uniform mat4 u_MVPMatrix;
uniform mat4 u_MVMatrix;

uniform vec2 u_Anchors;

uniform float u_Waves;
uniform float u_Amplitude;
uniform float u_Velocity;

uniform float u_Time;

attribute vec4 a_position;
attribute vec2 a_texCoord0;

varying vec4 v_position;
varying vec3 v_normal;

varying vec2 v_texCoord0;

void main(void)\
{
    vec4 pos = a_position;

    float val = u_Waves * (pos.x - u_Velocity * u_Time);
    pos.z = u_Amplitude * (pos.x - u_Anchors[0]) / abs(u_Anchors[1] - u_Anchors[0]) * sin(val);

    v_normal = vec3(normalize(vec2(-u_Waves * u_Amplitude * cos(val), 1.0)), 0.0);

    v_position = u_MVMatrix * pos;
    v_texCoord0 = a_texCoord0;

    gl_Position = u_MVPMatrix * pos;
});

static NSString* const kRZClothFSH = RZ_SHADER_SRC(
precision mediump float;

const float c_Shininess = 10.0;
                                                   
uniform vec3 u_LightPosition;
uniform vec3 u_Ambient;
uniform vec3 u_Diffuse;
uniform vec3 u_Specular;
uniform vec3 u_Attenuation;

uniform sampler2D u_Texture;

varying vec4 v_position;
varying vec3 v_normal;
varying highp vec2 v_texCoord0;

void main(void)
{
    vec4 tex = texture2D(u_Texture, v_texCoord0);

    vec3 scatteredLight = vec3(0.0);
    vec3 reflectedLight = vec3(0.0);

    vec3 nNormal = normalize(v_normal);

    vec3 lightDirection = u_LightPosition - vec3(v_position);
    float lightDistance = length(lightDirection);

    lightDirection = lightDirection / lightDistance;

    float attenuation = 1.0 / (u_Attenuation[0] + u_Attenuation[1] * lightDistance + u_Attenuation[2] * lightDistance * lightDistance);

    vec3 halfVector = normalize(lightDirection + vec3(0.0, 0.0, 1.0));

    float diffuse = max(0.0, dot(nNormal, lightDirection));
    float diffuseExists = step(0.001, diffuse);

    float specular = dot(nNormal, halfVector);
    specular = diffuseExists * pow(specular, c_Shininess);

    scatteredLight += (u_Ambient * attenuation + u_Diffuse * diffuse * attenuation);
    reflectedLight += (u_Specular * specular * attenuation);

    vec3 rgb = min(tex.rgb * scatteredLight + reflectedLight, vec3(1.0));

    gl_FragColor = vec4(rgb, tex.a);
});

@implementation RZClothEffect

+ (instancetype)clothEffect
{
    RZClothEffect *effect = [super effectWithVertexShader:kRZClothVSH fragmentShader:kRZClothFSH];
    
    effect.anchors = GLKVector2Make(-1.0f, 1.0f);
    
    effect.waveCount = 8.0f;
    effect.waveAmplitude = 0.1f;
    effect.waveVelocity = 0.8f;
    
    effect.lightPosition = GLKVector3Make(0.0f, 1.0f, 6.0f);
    effect.lightAttenuation = GLKVector3Make(1.0f, 0.02f, 0.017f);
    
    effect.ambientLight = GLKVector3Make(1.0f, 1.0f, 1.0f);
    effect.diffuseLight = GLKVector3Make(1.0f, 1.0f, 1.0f);
    effect.specularLight = GLKVector3Make(0.6f, 0.6f, 0.6f);
    
    effect.mvpUniform = @"u_MVPMatrix";
    effect.mvUniform = @"u_MVMatrix";
        
    return effect;
}

- (BOOL)link
{
    glBindAttribLocation(self.name, 0, "a_position");
    glBindAttribLocation(self.name, 1, "a_texCoord0");
    
    return [super link];
}

- (void)prepareToDraw
{
    [super prepareToDraw];
    
    glUniform2fv([self uniformLoc:@"u_Anchors"], 1, _anchors.v);
    
    glUniform1f([self uniformLoc:@"u_Waves"] , _waveCount);
    glUniform1f([self uniformLoc:@"u_Amplitude"] , _waveAmplitude);
    glUniform1f([self uniformLoc:@"u_Velocity"] , _waveVelocity);

    
    glUniform3fv([self uniformLoc:@"u_LightPosition"], 1, _lightPosition.v);
    glUniform3fv([self uniformLoc:@"u_Ambient"], 1, _ambientLight.v);
    glUniform3fv([self uniformLoc:@"u_Diffuse"], 1, _diffuseLight.v);
    glUniform3fv([self uniformLoc:@"u_Specular"], 1, _specularLight.v);
    glUniform3fv([self uniformLoc:@"u_Attenuation"], 1, _lightAttenuation.v);
    
    glUniform1f([self uniformLoc:@"u_Time"], CACurrentMediaTime());
}

@end
