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

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 lightPos;
uniform vec3 viewPos;
uniform sampler2D myTexture;
uniform sampler2D myTexture2;
uniform float alpha;

out vec4 fragColor;

void main() {
    vec3 norm = normalize(normal);
    vec3 lightDir = normalize(lightPos - fragPos);

    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    float ambientStrength = 0.2;
    vec3 ambient = ambientStrength * lightColor;

    vec3 viewDir = normalize(viewPos - fragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float specularStrength = 1;
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 16);
    vec3 specular = specularStrength * spec * lightColor;

    vec4 texture1 = texture(myTexture, textureCoord);
    vec4 texture2 = texture(myTexture2, vec2(1.0 - textureCoord.x, textureCoord.y));

    vec3 result = (ambient + diffuse + specular) * objectColor;
    fragColor = mix(
        texture1 * vec4(result, 1.0),
        texture2.rgba,
        texture2.a * alpha
    );
}
