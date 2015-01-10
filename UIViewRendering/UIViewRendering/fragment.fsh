precision mediump float;

const float c_Shininess = 10.0;

uniform vec3 u_LightPosition;
uniform vec3 u_Ambient;
uniform vec3 u_Diffuse;
uniform vec3 u_Specular;
uniform vec3 u_Attenuation;

uniform sampler2D u_Texture;

uniform int u_Emboss;

varying vec4 v_position;
varying vec3 v_normal;
varying highp vec2 v_texCoord0;

void main(void)
{
    vec4 tex = texture2D(u_Texture, v_texCoord0);
    
    if ( u_Emboss == 1) {
        highp vec2 onePixel = vec2(1.0 / (2.0 * 375.0), 1.0 / (2.0 * 667.0));
        mediump vec4 color;
        color.rgb = vec3(0.5);
        color -= texture2D(u_Texture, v_texCoord0 - onePixel) * 4.0;
        color += texture2D(u_Texture, v_texCoord0 + onePixel) * 4.0;
        tex.rgb = vec3(tex.a * (color.r + color.g + color.b) / 3.0);
    }

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
}