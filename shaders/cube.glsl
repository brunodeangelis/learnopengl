#type vertex
#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTextureCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 textureCoord;

void main()
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    textureCoord = aTextureCoord;
}

#type fragment
#version 410 core
in vec2 textureCoord;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform sampler2D myTexture;
uniform sampler2D myTexture2;
uniform float alpha;

out vec4 fragColor;

void main() {
    vec4 texture1 = texture(myTexture, textureCoord);
    vec4 texture2 = texture(myTexture2, vec2(1.0 - textureCoord.x, textureCoord.y));
    fragColor = mix(
        texture1 * vec4(objectColor, 1.0) * vec4(lightColor, 1.0),
        texture2.rgba,
        texture2.a * alpha
    );
}
