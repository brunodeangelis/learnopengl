#version 410 core

in vec2 texCoords;

uniform sampler2D screenTexture;
  
out vec4 fragColor;

const int KERNEL_SIZE = 3; // Meaning 3x3
const int MAX_SIZE = KERNEL_SIZE * KERNEL_SIZE;
const float OFFSET = 1.0 / 300.0; // Could be read as intensity

float kernel[MAX_SIZE] = float[](
    -1, -1, -1,
    -1,  9, -1,
    -1, -1, -1
);

vec2 offsets[MAX_SIZE] = vec2[](
    vec2(-OFFSET,  OFFSET), // top-left
    vec2( 0.0f,    OFFSET), // top-center
    vec2( OFFSET,  OFFSET), // top-right
    vec2(-OFFSET,  0.0f),   // center-left
    vec2( 0.0f,    0.0f),   // center-center
    vec2( OFFSET,  0.0f),   // center-right
    vec2(-OFFSET, -OFFSET), // bottom-left
    vec2( 0.0f,   -OFFSET), // bottom-center
    vec2( OFFSET, -OFFSET)  // bottom-right    
);

vec3 texSamples[MAX_SIZE];

void main() {
    for (int i = 0; i < MAX_SIZE; i++) {
        texSamples[i] = vec3(texture(screenTexture, texCoords.st + offsets[i]));
    }

    vec3 col = vec3(0.0);
    for (int i = 0; i < MAX_SIZE; i++) {
        col += texSamples[i] * kernel[i];
    }

    fragColor = vec4(col, 1.0);
}
