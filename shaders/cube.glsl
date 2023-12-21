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
in vec2 textureCoord;
in vec3 normal;
in vec3 fragPos;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    sampler2D emission;
    float shininess;
};

struct Light {
    vec3 pos;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform Material material;
uniform Light light;

uniform vec3 viewPos;

out vec4 fragColor;

void main() {
    vec3 diffuseColor = texture(material.diffuse, textureCoord).rgb;
    vec3 specularColor = texture(material.specular, textureCoord).rgb;
    vec3 emissionColor = texture(material.emission, (textureCoord - 0.1) * 1.25).rgb;

    // ambient
    vec3 ambient = light.ambient * diffuseColor;

    // diffuse
    vec3 norm = normalize(normal);
    vec3 lightDir = normalize(light.pos - fragPos);
    float diffuseIntensity = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * diffuseColor * diffuseIntensity; 

    // specular
    vec3 viewDir = normalize(viewPos - fragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float specularIntensity = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * specularIntensity * specularColor;

    vec3 result = ambient + diffuse + specular + emissionColor;
    fragColor = vec4(result, 1.0);
}
