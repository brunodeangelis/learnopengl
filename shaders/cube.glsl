#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTextureCoord;
layout (location = 2) in vec3 aNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform bool setNormal;

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
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
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
uniform sampler2D myTexture;
uniform sampler2D myTexture2;
uniform float alpha;

out vec4 fragColor;

void main() {
    vec3 ambient = light.ambient * material.ambient;

    // diffuse
    vec3 norm = normalize(normal);
    vec3 lightDir = normalize(light.pos - fragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = light.diffuse * (diff * material.diffuse);

    // specular
    vec3 viewDir = normalize(viewPos - fragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = light.specular * (spec * material.specular);

    vec3 result = ambient + diffuse + specular;
    fragColor = vec4(result, 1.0);
    
    return;

    vec4 texture1 = texture(myTexture, textureCoord);
    vec4 texture2 = texture(myTexture2, vec2(1.0 - textureCoord.x, textureCoord.y));

    fragColor = mix(
        texture1 * vec4(result, 1.0),
        texture2.rgba,
        texture2.a * alpha
    );
}
