#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
}

#type fragment
#version 410 core

uniform vec3 color;

out vec4 fragColor;

void main() {
    fragColor = vec4(color, 1.0);
}
