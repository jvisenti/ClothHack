attribute vec4 a_position;

uniform mat4 u_MVPMatrix;

uniform float u_timeOffset;
uniform float u_velocity;
uniform float u_waveNumber;
uniform float u_amplitude;

uniform mat4 u_modelViewMatrix;
uniform mat3 u_normalMatrix;

attribute vec2 a_texCoord0;
varying vec2 v_texCoord0;

void main(void)
{
    vec4 pos = a_position;

    float value = u_waveNumber * (pos.x - u_velocity * u_timeOffset * 2.0);
    pos.z = u_amplitude*pos.x * sin( value );

    vec3 n = vec3(0.0);
    n.xy = normalize(vec2(-u_waveNumber * u_amplitude * cos( value ), 1.0));


    gl_Position = u_MVPMatrix * pos;
    v_texCoord0 = a_texCoord0;
}