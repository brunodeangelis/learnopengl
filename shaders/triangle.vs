#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

uniform float yFactor;

out vec3 vertexPos;
out vec3 vertexColor;

void main()
{
    gl_Position = vec4(aPos.x, aPos.y + yFactor, aPos.z, 1.0);
    vertexPos = gl_Position.xyz;
    vertexColor = aColor;
}
