attribute vec4 a_position;

uniform mat4 u_MVPMatrix;

attribute vec2 a_texCoord0;
varying vec2 v_texCoord0;

void main(void)
{
    gl_Position = u_MVPMatrix * a_position;
    v_texCoord0 = a_texCoord0;
}