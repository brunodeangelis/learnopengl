// 6. Coordinate Systems
// https://learnopengl.com/Getting-started/Coordinate-Systems

package main

import "core:fmt"
import "core:runtime"
import "core:math"
import lalg "core:math/linalg"

import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

window: glfw.WindowHandle
viewport: [4]i32

cube_verts := [?]f32 {
	-0.5, -0.5, -0.5,  0.0, 0.0,
	0.5, -0.5, -0.5,   1.0, 0.0,
	0.5,  0.5, -0.5,   1.0, 1.0,
	0.5,  0.5, -0.5,   1.0, 1.0,
   -0.5,  0.5, -0.5,   0.0, 1.0,
   -0.5, -0.5, -0.5,   0.0, 0.0,

   -0.5, -0.5,  0.5,   0.0, 0.0,
	0.5, -0.5,  0.5,   1.0, 0.0,
	0.5,  0.5,  0.5,   1.0, 1.0,
	0.5,  0.5,  0.5,   1.0, 1.0,
   -0.5,  0.5,  0.5,   0.0, 1.0,
   -0.5, -0.5,  0.5,   0.0, 0.0,

   -0.5,  0.5,  0.5,   1.0, 0.0,
   -0.5,  0.5, -0.5,   1.0, 1.0,
   -0.5, -0.5, -0.5,   0.0, 1.0,
   -0.5, -0.5, -0.5,   0.0, 1.0,
   -0.5, -0.5,  0.5,   0.0, 0.0,
   -0.5,  0.5,  0.5,   1.0, 0.0,

	0.5,  0.5,  0.5,   1.0, 0.0,
	0.5,  0.5, -0.5,   1.0, 1.0,
	0.5, -0.5, -0.5,   0.0, 1.0,
	0.5, -0.5, -0.5,   0.0, 1.0,
	0.5, -0.5,  0.5,   0.0, 0.0,
	0.5,  0.5,  0.5,   1.0, 0.0,

   -0.5, -0.5, -0.5,   0.0, 1.0,
	0.5, -0.5, -0.5,   1.0, 1.0,
	0.5, -0.5,  0.5,   1.0, 0.0,
	0.5, -0.5,  0.5,   1.0, 0.0,
   -0.5, -0.5,  0.5,   0.0, 0.0,
   -0.5, -0.5, -0.5,   0.0, 1.0,

   -0.5,  0.5, -0.5,   0.0, 1.0,
	0.5,  0.5, -0.5,   1.0, 1.0,
	0.5,  0.5,  0.5,   1.0, 0.0,
	0.5,  0.5,  0.5,   1.0, 0.0,
   -0.5,  0.5,  0.5,   0.0, 0.0,
   -0.5,  0.5, -0.5,   0.0, 1.0,
}
cube_positions := [?]v3{
	{0, 0, 0},
	{2, 5, -15},
    {-1.5, -2.2, -2.5},
    {-3.8, -2, -12.3},
    { 2.4, -0.4, -3.5},
    {-1.7, 3, -7.5},
    {1.3, -2, -2.5},
    {1.5, 2, -2.5},
    {1.5, 0.2, -1.5},
    {-1.3, 1, -1.5},
}
grass_texture, face_texture: u32

tri_verts := [?]f32{
	// xyz            // rgb
	0.5, 0.5, 0.0,    1.0, 0.0, 0.0,
	0.75, -0.5, 0.0,  0.0, 1.0, 0.0,
	0.25, -0.5, 0.0,  0.0, 0.0, 1.0,
}

HOW_MANY :: 2
VAOs := make([]u32, HOW_MANY)
VBOs := make([]u32, HOW_MANY)
cube_shader, tri_shader: u32

wireframe: bool

texture_alpha: f32 = 0.3

main :: proc() {
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)	
	when ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
	}

	viewport[2] = WINDOW_WIDTH
	viewport[3] = WINDOW_HEIGHT
	window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hi mom!", nil, nil)
	if window == nil {
		fmt.print("Failed to create GLFW window\n")
		glfw.Terminate()
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, fb_size_callback)
	glfw.SetKeyCallback(window, key_callback)

	// This does what gladLoadGLLoader() would do
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	fmt.println(gl.GetString(gl.VERSION))

	gl.Enable(gl.DEPTH_TEST)

	gl.GenVertexArrays(HOW_MANY, raw_data(VAOs))
	gl.GenBuffers(HOW_MANY, raw_data(VBOs))

	gl.BindVertexArray(VAOs[0])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(cube_verts), &cube_verts, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	gl.BindVertexArray(VAOs[1])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[1])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(tri_verts), &tri_verts, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	cube_shader, _ = load_shader("cube")
	tri_shader, _ = load_shader("triangle")

	stbi.set_flip_vertically_on_load(1)

	image_width, image_height, image_chans: i32
	image_bytes := stbi.load("images/grass.png", &image_width, &image_height, &image_chans, 0)
	defer stbi.image_free(image_bytes)	
	gl.GenTextures(1, &grass_texture)
	gl.BindTexture(gl.TEXTURE_2D, grass_texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, i32(image_width), i32(image_height), 0, gl.RGB, gl.UNSIGNED_BYTE, image_bytes)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	image2_width, image2_height, image2_chans: i32
	image2_bytes := stbi.load("images/face.png", &image2_width, &image2_height, &image2_chans, 0)
	defer stbi.image_free(image2_bytes)
	gl.GenTextures(1, &face_texture)
	gl.BindTexture(gl.TEXTURE_2D, face_texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(image2_width), i32(image2_height), 0, gl.RGBA, gl.UNSIGNED_BYTE, image2_bytes)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	use_shader(cube_shader)
	set_uniform(cube_shader, "myTexture", 0)
	set_uniform(cube_shader, "myTexture2", 1)

	for !glfw.WindowShouldClose(window) {
		render()
		glfw.PollEvents()
	}
}

render :: proc() {
	time := glfw.GetTime()

	gl.ClearColor(0.2, 0.3, 0.3, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	if wireframe {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	} else {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	}

	use_shader(cube_shader)
	view_mat := lalg.matrix4_translate_f32({0, 0, -5})
	proj_mat := lalg.matrix4_perspective_f32(math.to_radians(f32(45)), f32(viewport[2]) / f32(viewport[3]), 0.01, 1000)
	set_uniform(cube_shader, "view", &view_mat)
	set_uniform(cube_shader, "projection", &proj_mat)
	sin_time01 := math.sin(time) * 0.5 + 0.5
	set_uniform(cube_shader, "myColor", v4{0.5, f32(sin_time01), 0.25, 1.0})
	set_uniform(cube_shader, "alpha", texture_alpha)
	gl.ActiveTexture(gl.TEXTURE0);
	gl.BindTexture(gl.TEXTURE_2D, grass_texture)
	gl.ActiveTexture(gl.TEXTURE1);
	gl.BindTexture(gl.TEXTURE_2D, face_texture)
	gl.BindVertexArray(VAOs[0])
	for pos, idx in cube_positions {
		rotate_by := f32(20 * idx)
		if idx % 3 == 0 {
			rotate_by += f32(time * 2)
		}
		model_mat := lalg.matrix4_rotate_f32(rotate_by, {1, 0.3, 0.5})
		model_mat = lalg.matrix4_translate_f32(pos) * model_mat
		set_uniform(cube_shader, "model", &model_mat)

		gl.DrawArrays(gl.TRIANGLES, 0, 36)
	}
    
	use_shader(tri_shader)
	set_uniform(tri_shader, "yFactor", f32(math.sin(time) * 0.5))
	gl.BindVertexArray(VAOs[1])
	gl.DrawArrays(gl.TRIANGLES, 0, 3)

	glfw.SwapBuffers(window)
}

fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Implicit context needs to be set explicitly for "c" procs
	// if inside it we're calling non-c procs (draw in this case)
	context = runtime.default_context()

	gl.Viewport(0, 0, width, height)
	gl.GetIntegerv(gl.VIEWPORT, &viewport[0]);
	render() // Draw while resizing
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if action == glfw.PRESS {
		switch key {
		case glfw.KEY_W:
			wireframe = !wireframe
		case glfw.KEY_ESCAPE:
			glfw.SetWindowShouldClose(window, true)
		case glfw.KEY_UP:
			texture_alpha += 0.1
			if texture_alpha >= 1.0 do texture_alpha = 1.0
		case glfw.KEY_DOWN:
			texture_alpha -= 0.1
			if texture_alpha <= 0.0 do texture_alpha = 0.0
		}
	}
}
