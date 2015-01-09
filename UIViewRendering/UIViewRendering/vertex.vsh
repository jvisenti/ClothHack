attribute vec4 a_position;

uniform mat4 u_MVPMatrix;

uniform float u_timeOffset;

attribute vec2 a_texCoord0;
varying vec2 v_texCoord0;

void main(void)
{
    vec4 pos = a_position;
    pos.z = sin(15.0 * pos.x + u_timeOffset) / 2.0;
    gl_Position = u_MVPMatrix * pos;
    v_texCoord0 = a_texCoord0;
}