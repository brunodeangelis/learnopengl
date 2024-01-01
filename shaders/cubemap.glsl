#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;

uniform mat4 projection;
uniform mat4 view;

out vec3 texCoords;

void main() {
    gl_Position = projection * view * vec4(aPos, 1.0);
    texCoords = aPos;
}

#type fragment
#version 410 core
in vec3 texCoords;

uniform samplerCube skybox;

out vec4 fragColor;

void main() {
    fragColor = texture(skybox, texCoords);
}
