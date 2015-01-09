#version 300 es

precision mediump float;

struct BHGLLightInfo
{
    int type;
    float enabled;
    vec4 ambientColor;
    vec4 diffuseColor;
    vec4 specularColor;
    vec3 position;
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
    vec3 halfVector;
    vec3 spotDirection;
    float spotCutoff;
    float spotExponent;
};

struct BHGLMaterialInfo
{
    vec4 emission;
    vec4 surface;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
};

uniform BHGLLightInfo u_Lights[1];

uniform BHGLMaterialInfo u_Material;

uniform sampler2D u_Texture;

in vec4 v_position;
in vec3 v_normal;
in highp vec2 v_texCoord0;

out vec4 o_frag_color;

void main(void)
{
    BHGLLightInfo lightInfo = u_Lights[0];
    
    vec4 tex = texture(u_Texture, v_texCoord0);
    
    vec4 scatteredLight = vec4(0.0);
    vec4 reflectedLight = vec4(0.0);
    
    vec3 nNormal = normalize(v_normal);
    
    vec3 lightDirection = lightInfo.position - vec3(v_position);
    float lightDistance = length(lightDirection);
    
    lightDirection = lightDirection / lightDistance;
    
    float attenuation = 1.0 / (lightInfo.constantAttenuation + lightInfo.linearAttenuation * lightDistance + lightInfo.quadraticAttenuation * lightDistance * lightDistance);
    
    vec3 halfVector = normalize(lightDirection + vec3(0.0, 0.0, 1.0));
    
    float diffuse = max(0.0, dot(nNormal, lightDirection));
    float diffuseExists = step(0.001, diffuse);
    
    float specular = dot(nNormal, halfVector);
    specular = diffuseExists * pow(specular, u_Material.shininess);
    
    scatteredLight += (lightInfo.ambientColor * u_Material.ambient * attenuation + lightInfo.diffuseColor * u_Material.diffuse * diffuse * attenuation);
    reflectedLight += (lightInfo.specularColor * u_Material.specular * specular * attenuation);
    
    vec3 rgb = min(u_Material.emission.rgb + (u_Material.surface.rgb + tex.rgb) * scatteredLight.rgb + reflectedLight.rgb, vec3(1.0));
    
    o_frag_color = vec4(rgb, u_Material.surface.a * tex.a);
}