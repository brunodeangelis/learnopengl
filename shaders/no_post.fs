#version 410 core

in vec2 texCoords;

uniform sampler2D screenTexture;
  
out vec4 fragColor;

void main() {
    fragColor = texture(screenTexture, texCoords);
}
