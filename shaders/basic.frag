
#version 330 core
out vec4 FragColor;

struct Material {
    sampler2D diffuse;
    sampler2D specular;    
    float shininess;
}; 
struct DirLight {
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
struct PointLight {
    vec3 position;

    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};
struct SpotLight {
    vec3 position;
    vec3 direction;

    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    
    float cutOff;
    float outerCutOff;
    int FlashLightEnable;
};

#define NR_POINT_LIGHTS 4

in vec3 vNormal;
in vec3 FragPos;
in vec2 vTexCoord;
in vec3 vLocalPos;

uniform float currFrame;
uniform sampler2D texture1;
uniform sampler2D texture2;

uniform vec3 viewPos;

uniform Material material;
uniform DirLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLight;

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir);
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir);

void main()
{
    // Basic properties
    vec3 norm = normalize(vNormal);
    vec3 viewDir = normalize(viewPos - FragPos);

    // Point lights
    // for (int i = 0; i < NR_POINT_LIGHTS; i++)
    vec3 result = CalcPointLight(pointLights[0], norm, FragPos, viewDir);  
    // Spot light
    if (spotLight.FlashLightEnable == 1)
        result += CalcSpotLight(spotLight, norm, FragPos, viewDir);

    result += vec3(0.1f);

    FragColor = vec4(result, 1.0);
}   

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir)
{
    vec3 lightDir = normalize(-light.direction);
    // diffuse
    float diff = max(dot(normal, lightDir), 0.0);
    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    // combine
    vec3 ambient  = light.ambient  * vec3(texture(material.diffuse, vTexCoord));
    vec3 diffuse  = light.diffuse  * diff * vec3(texture(material.diffuse, vTexCoord));
    vec3 specular = light.specular * spec * texture(material.specular, vTexCoord).rgb;
    return (ambient + diffuse + specular);
}
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse
    float diff = max(dot(normal, lightDir), 0.0);
    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    // dims lighting based on distance (attenuation)
    float distance = length(light.position - fragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
                                light.quadratic * (distance * distance));
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, vTexCoord));
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, vTexCoord));
    vec3 specular = light.specular * spec * texture(material.specular, vTexCoord).rgb;
    ambient  *= attenuation; 
    diffuse  *= attenuation;
    specular *= attenuation; 
    return (ambient + diffuse + specular);
}
vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
    vec3 lightDir = normalize(light.position - fragPos);
    // diffuse
    float diff = max(dot(normal, lightDir), 0.0);
    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    // dims lighting based on distance (attenuation)
    float distance = length(light.position - FragPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
                                light.quadratic * (distance * distance));
    // spotlight intensity                            
    float theta = dot(lightDir, normalize(-light.direction));
    float epsilon = light.cutOff - light.outerCutOff;
    // creates soft edges for spotlight
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);
    // combine result
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, vTexCoord));
    vec3 diffuse = light.diffuse * diff * vec3(texture(material.diffuse, vTexCoord));
    vec3 specular = light.specular * spec * vec3(texture(material.specular, vTexCoord));
    ambient *= intensity * attenuation;;
    diffuse *= intensity * attenuation;;
    specular *= intensity * attenuation;
    return (ambient + diffuse + specular);
}

// Phase 1: Directional lighting
    // vec3 result = CalcDirLight(dirLight, norm, viewDir);  