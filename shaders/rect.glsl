#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos, 1.0);
}

#type fragment
#version 410 core
out vec4 fragColor;

uniform vec4 myColor;

void main() {
    fragColor = myColor;
}
