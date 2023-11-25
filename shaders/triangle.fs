#version 410 core
out vec4 fragColor;

in vec3 vertexPos;
in vec3 vertexColor;

void main() {
    fragColor = vec4(vertexPos, 1.0f);
} 
