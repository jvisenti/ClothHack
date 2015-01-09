#version 300 es

uniform mat4 u_MVPMatrix;
uniform mat4 u_MVMatrix;
uniform mat3 u_NormalMatrix;

uniform float u_anchor;
uniform float u_timeOffset;
uniform float u_velocity;
uniform float u_waveNumber;
uniform float u_amplitude;

uniform mat4 u_modelViewMatrix;
uniform mat3 u_normalMatrix;

in vec4 a_position;
in vec2 a_texCoord0;

out vec4 v_position;
out vec3 v_normal;

out vec2 v_texCoord0;

void main(void)
{
    vec4 pos = a_position;

    float value = u_waveNumber * (pos.x - u_velocity * u_timeOffset);
    pos.z = u_amplitude * (pos.x - u_anchor) / 2.0 * sin(value);

    vec3 n = vec3(0.0);
    n.xy = normalize(vec2(-u_waveNumber * u_amplitude * cos(value), 1.0));
    
    v_position = u_MVMatrix * pos;
    v_normal = n;
    
    v_texCoord0 = a_texCoord0;
    
    gl_Position = u_MVPMatrix * pos;
}