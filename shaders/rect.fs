#version 410 core
out vec4 fragColor;

uniform vec4 myColor;

void main() {
    fragColor = myColor;
}
