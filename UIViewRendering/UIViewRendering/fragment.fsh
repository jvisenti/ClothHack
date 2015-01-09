varying lowp vec2 v_texCoord0;

uniform sampler2D u_texture;

void main(void)
{
//    gl_FragColor = texture2D(u_texture, v_texCoord0);
    
    highp vec2 onePixel = vec2(1.0 / (2.0 * 375.0), 1.0 / (2.0 * 667.0));
    
    mediump float a = texture2D(u_texture, v_texCoord0).a;
    
    mediump vec4 color;
    color.rgb = vec3(0.5);
    color -= texture2D(u_texture, v_texCoord0 - onePixel) * 4.0;
    color += texture2D(u_texture, v_texCoord0 + onePixel) * 4.0;
    
    color.rgb = vec3(a * (color.r + color.g + color.b) / 3.0);
    
    gl_FragColor = vec4(color.rgb, a);
}