#version 410 core

in vec2 texCoords;

uniform sampler2D screenTexture;
  
out vec4 fragColor;

void main() {
    vec4 rt = texture(screenTexture, texCoords);
    float average = 0.2126 * rt.r + 0.7152 * rt.g + 0.0722 * rt.b;
    fragColor = vec4(average, average, average, 1.0);
}
