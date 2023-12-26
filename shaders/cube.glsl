#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTextureCoord;
layout (location = 2) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 textureCoord;
out vec3 normal;
out vec3 fragPos;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    textureCoord = aTextureCoord;

    // Op better done once in CPU rather than for each vertex
    normal = mat3(transpose(inverse(model))) * aNormal;

    fragPos = vec3(model * vec4(aPos, 1.0));
}

#type fragment
#version 410 core
struct Material {
    sampler2D diffuse;
    sampler2D specular;
    sampler2D emission;
    float shininess;
};

struct DirectionalLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    vec3 dir;
};

struct PointLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    vec3 pos;
    float linear;
    float quadratic;
};

struct SpotLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    vec3 dir;

    vec3 pos;
    float linear;
    float quadratic;

    float cutOff;
    float outerCutOff;
};

#define NR_POINT_LIGHTS 4

in vec2 textureCoord;
in vec3 normal;
in vec3 fragPos;

uniform Material material;
uniform DirectionalLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLight;
uniform vec3 viewPos;

out vec4 fragColor;

vec3 diffuseColor = texture(material.diffuse, textureCoord).rgb;
vec3 specularColor = texture(material.specular, textureCoord).rgb;
vec3 emissionColor = texture(material.emission, (textureCoord - 0.1) * 1.25).rgb;

// function prototypes
vec3 calcDirLight(DirectionalLight light, vec3 normal, vec3 viewDir);
vec3 calcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir);

void main() {
    vec3 norm = normalize(normal);
    vec3 viewDir = normalize(viewPos - fragPos);

    vec3 result = vec3(0.0);

    for (int i = 0; i < NR_POINT_LIGHTS; i++) {
        result += calcPointLight(pointLights[i], norm, fragPos, viewDir);
    }

    result += calcDirLight(dirLight, norm, viewDir);
    result += calcSpotLight(spotLight, norm, fragPos, viewDir);
    result += emissionColor;

    fragColor = vec4(result, 1.0);
}

vec3 calcDirLight(DirectionalLight light, vec3 normal, vec3 viewDir) {
    // ambient
    vec3 ambient = light.ambient * diffuseColor;

    // diffuse
    // negate direction to be from fragment to light
    vec3 lightDir = normalize(-light.dir);
    float diffuseIntensity = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diffuseColor * diffuseIntensity; 

    // specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float specularIntensity = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * specularIntensity * specularColor;
    
    return ambient + diffuse + specular;
}

vec3 calcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 ambient = light.ambient * diffuseColor;

    vec3 lightDir = normalize(light.pos - fragPos);
    float diffuseIntensity = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diffuseColor * diffuseIntensity;

    vec3 reflectDir = reflect(-lightDir, normal);
    float specularIntensity = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * specularIntensity * specularColor;

    float dist = length(light.pos - fragPos);
    float attenuation = 1.0 / (1.0 + light.linear * dist + light.quadratic * (dist*dist));

    ambient *= attenuation;
    diffuse *= attenuation;
    specular *= attenuation;

    return ambient + diffuse + specular;
}

vec3 calcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    vec3 ambient = light.ambient * diffuseColor;

    vec3 lightDir = normalize(light.pos - fragPos);
    float diffuseIntensity = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diffuseColor * diffuseIntensity;

    vec3 reflectDir = reflect(-lightDir, normal);
    float specularIntensity = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * specularIntensity * specularColor;

    float dist = length(light.pos - fragPos);
    float attenuation = 1.0 / (1.0 + light.linear * dist + light.quadratic * (dist*dist));

    float theta = dot(lightDir, normalize(-light.dir));
    float epsilon = light.cutOff - light.outerCutOff;
    float spotLightIntensity = clamp((theta - light.outerCutOff) / epsilon, 0.0, 1.0);

    ambient *= attenuation * spotLightIntensity;
    diffuse *= attenuation * spotLightIntensity;
    specular *= attenuation * spotLightIntensity;

    return ambient + diffuse + specular;
}
