#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 texCoords;

void main() {
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    texCoords = aTexCoords;
}

#type fragment
#version 410 core
out vec4 fragColor;

in vec2 texCoords;

uniform sampler2D texture0;

void main() {
    vec4 texColor = texture(texture0, texCoords);
    fragColor = texColor;
}