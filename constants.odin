package main

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 1

WINDOW_WIDTH :: 800
WINDOW_HEIGHT :: 600

SHADERS_EXTENSION :: "glsl"
SHADERS_VERTEX_EXTENSION :: "vs"
SHADERS_FRAGMENT_EXTENSION :: "fs"
SHADERS_BASE_PATH :: "shaders"
SHADERS_VERTEX_SEPARATOR :: "#type vertex"
SHADERS_FRAGMENT_SEPARATOR :: "#type fragment"

TEXTURES_BASE_PATH :: "textures"

CUBEMAPS_BASE_PATH :: "cubemaps"
CUBEMAP_FILE_NAMES :: []string{
    "posx.jpg",
    "negx.jpg",
    "posy.jpg",
    "negy.jpg",
    "posz.jpg",
    "negz.jpg",
}

ATT_LINEAR :: 0.09
ATT_QUADRATIC :: 0.032
