// 18. Framebuffers
// https://learnopengl.com/Advanced-OpenGL/Framebuffers

package main

import "core:fmt"
import "core:strings"
import "core:runtime"
import "core:math"
import "core:slice"
import lalg "core:math/linalg"

import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

window: glfw.WindowHandle
viewport: [4]i32

cube_verts := [?]f32 {
	// xyz                // uv     // normal
	// Back face
	-0.5, -0.5, -0.5,     0, 0,     0,  0, -1, // BL
	0.5,  0.5, -0.5,      1, 1,     0,  0, -1, // TR
	0.5, -0.5, -0.5,      1, 0,     0,  0, -1, // BR 
	0.5,  0.5, -0.5,      1, 1,     0,  0, -1, // TR
   -0.5, -0.5, -0.5,      0, 0,     0,  0, -1, // BL
   -0.5,  0.5, -0.5,      0, 1,     0,  0, -1, // TL

   // Front face
   -0.5, -0.5,  0.5,      0, 0,     0,  0,  1, // BL
	0.5, -0.5,  0.5,      1, 0,     0,  0,  1, // BR
	0.5,  0.5,  0.5,      1, 1,     0,  0,  1, // TR
	0.5,  0.5,  0.5,      1, 1,     0,  0,  1, // TR
   -0.5,  0.5,  0.5,      0, 1,     0,  0,  1, // TL
   -0.5, -0.5,  0.5,      0, 0,     0,  0,  1, // BL

   // Left face
   -0.5,  0.5,  0.5,      1, 0,    -1,  0,  0, // TR
   -0.5,  0.5, -0.5,      1, 1,    -1,  0,  0, // TL
   -0.5, -0.5, -0.5,      0, 1,    -1,  0,  0, // BL
   -0.5, -0.5, -0.5,      0, 1,    -1,  0,  0, // BL
   -0.5, -0.5,  0.5,      0, 0,    -1,  0,  0, // BR
   -0.5,  0.5,  0.5,      1, 0,    -1,  0,  0, // TR

   // Right face
	0.5,  0.5,  0.5,      1, 0,     1,  0,  0, // TL
	0.5, -0.5, -0.5,      0, 1,     1,  0,  0, // BR
	0.5,  0.5, -0.5,      1, 1,     1,  0,  0, // TR
	0.5, -0.5, -0.5,      0, 1,     1,  0,  0, // BR
	0.5,  0.5,  0.5,      1, 0,     1,  0,  0, // TL
	0.5, -0.5,  0.5,      0, 0,     1,  0,  0, // BL

	// Bottom face
   -0.5, -0.5, -0.5,      0, 1,     0, -1,  0, // TR
	0.5, -0.5, -0.5,      1, 1,     0, -1,  0, // TL
	0.5, -0.5,  0.5,      1, 0,     0, -1,  0, // BL
	0.5, -0.5,  0.5,      1, 0,     0, -1,  0, // BL
   -0.5, -0.5,  0.5,      0, 0,     0, -1,  0, // BR
   -0.5, -0.5, -0.5,      0, 1,     0, -1,  0, // TR

   // Top face
   -0.5,  0.5, -0.5,      0, 1,     0,  1,  0, // TL
    0.5,  0.5,  0.5,      1, 0,     0,  1,  0, // BR
	0.5,  0.5, -0.5,      1, 1,     0,  1,  0, // TR
	0.5,  0.5,  0.5,      1, 0,     0,  1,  0, // BR
   -0.5,  0.5, -0.5,      0, 1,     0,  1,  0, // TL
   -0.5,  0.5,  0.5,      0, 0,     0,  1,  0, // BL
}

cube_positions := []v3{
	{0,     0,    0},
	{2,     5,   -15},
    {-1.5, -2.2, -2.5},
    {-3.8, -2,   -12.3},
    { 2.4, -0.4, -3.5},
    {-1.7,  3,   -7.5},
    {1.3,  -2,   -2.5},
    {1.5,   2,   -2.5},
    {1.5,   0.2, -1.5},
    {-1.3,  1,   -1.5},
}

quad_3d_verts := [?]f32{
	// pos          // tex coords
	0,  0.5,  0,    0,  1,
	0, -0.5,  0,    0,  0,
	1, -0.5,  0,    1,  0,

	0,  0.5,  0,    0,  1,
	1, -0.5,  0,    1,  0,
	1,  0.5,  0,    1,  1,
}

quad_fullscreen_verts := [?]f32{
    // pos     // tex coords
    -1,  1,    0, 1,
    -1, -1,    0, 0,
     1, -1,    1, 0,

    -1,  1,    0, 1,
     1, -1,    1, 0,
     1,  1,    1, 1,
}

windows := []v3{
	{-1.5,  0, -0.48},
	{ 1.5,  0,  0.51},
	{ 0,    0,  0.7},
	{-0.3,  0, -2.3},
	{ 0.5,  0, -0.6},
}

container_texture,
container_specular,
container_emission,
window_texture: u32

BUFFER_COUNT :: 3
VAOs := make([]u32, BUFFER_COUNT)
VBOs := make([]u32, BUFFER_COUNT)
framebuffer, rbo, tex_color_buffer: u32

cube_shader,
single_color_shader,
window_shader,
no_post_shader,
sharpen_shader,
grayscale_shader,
blur_shader,
edge_shader: u32

wireframe: bool

camera := Camera{
	pos = {0, 0, 3},
	up = {0, 1, 0},
	speed = 10,
	yaw = -90,
	front = {0, 0, -1},
	fov = 45,
}

moving_left, moving_right, moving_forwards, moving_backwards, moving_up, moving_down: bool
current_frame_time, last_frame_time, delta_time: f64
first_mouse := true
last_mouse_pos: v2

directional_light := Directional_Light{
	color = {1, 1, 1},
	pos = {0, 0, 0},
	dir = {-0.2, -1, -0.3},
}

point_lights := []Point_Light{
	{
		color = {1, 1, 1},
		pos = {0.7, 0.2, 2},
		linear = ATT_LINEAR,
		quadratic = ATT_QUADRATIC,
	},
	{
		color = {1, 1, 1},
		pos = {2.3, -3.3, -4},
		linear = ATT_LINEAR,
		quadratic = ATT_QUADRATIC,
	},
	{
		color = {1, 1, 1},
		pos = {-4, 2, -12},
		linear = ATT_LINEAR,
		quadratic = ATT_QUADRATIC,
	},
	{
		color = {1, 1, 1},
		pos = {0, 0, -3},
		linear = ATT_LINEAR,
		quadratic = ATT_QUADRATIC,
	},
}

spot_light := Spot_Light{
	color = {1, 1, 1},
	linear = ATT_LINEAR,
	quadratic = ATT_QUADRATIC,
}

current_postprocess := Postprocess.SHARPEN

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
	window = glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hola ma :)", nil, nil)
	if window == nil {
		fmt.print("Failed to create GLFW window\n")
		glfw.Terminate()
		return
	}

	glfw.MakeContextCurrent(window)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED);  
	glfw.SetFramebufferSizeCallback(window, fb_size_callback)
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)

	// This does what gladLoadGLLoader() would do
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	fmt.println(gl.GetString(gl.VERSION))

	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS) // Default comparison function

	gl.Enable(gl.STENCIL_TEST)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK) // Default
	gl.FrontFace(gl.CCW) // Default

	// Custom fb will be for color data
	gl.GenFramebuffers(1, &framebuffer)
	gl.BindFramebuffer(gl.FRAMEBUFFER, framebuffer)
	defer gl.DeleteFramebuffers(1, &framebuffer)

	// Render buffer will take care of depth and stencil buffs
	gl.GenRenderbuffers(1, &rbo)
	gl.BindRenderbuffer(gl.RENDERBUFFER, rbo)
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, WINDOW_WIDTH*2, WINDOW_HEIGHT*2)
	gl.BindRenderbuffer(gl.RENDERBUFFER, 0)
	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, rbo)

	gl.GenTextures(1, &tex_color_buffer)
	gl.BindTexture(gl.TEXTURE_2D, tex_color_buffer)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, WINDOW_WIDTH*2, WINDOW_HEIGHT*2, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.BindTexture(gl.TEXTURE_2D, 0)

	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex_color_buffer, 0)

	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE {
		fmt.println("ERROR::FRAMEBUFFER:: Framebuffer is not complete")
	}
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0) // Revert to default fb

	gl.GenVertexArrays(BUFFER_COUNT, raw_data(VAOs))
	gl.GenBuffers(BUFFER_COUNT, raw_data(VBOs))

	// Textured Cube
	gl.BindVertexArray(VAOs[0])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[0])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(cube_verts), &cube_verts, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 5 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	// Windows
	gl.BindVertexArray(VAOs[1])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[1])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_3d_verts), &quad_3d_verts, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	// Fullscreen quad
	gl.BindVertexArray(VAOs[2])
	gl.BindBuffer(gl.ARRAY_BUFFER, VBOs[2])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(quad_fullscreen_verts), &quad_fullscreen_verts, gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	cube_shader, _ = load_shader("cube")
	single_color_shader, _ = load_shader("single_color")
	window_shader, _ = load_shader("window")
	no_post_shader, _ = load_shader("rt", "no_post")
	sharpen_shader, _ = load_shader("rt", "sharpen")
	grayscale_shader, _ = load_shader("rt", "grayscale")
	blur_shader, _ = load_shader("rt", "blur")
	edge_shader, _ = load_shader("rt", "edge")

	stbi.set_flip_vertically_on_load(1)
	
	container_texture = load_texture("container.png")
	container_specular = load_texture("container_specular.png")
	container_emission = load_texture("container_emission.jpg", gl.CLAMP_TO_BORDER, gl.CLAMP_TO_BORDER)
	window_texture = load_texture("window.png")

	world_up := v3{0, 1, 0}
	camera.right = lalg.normalize(lalg.cross(world_up, camera.dir))
	spot_light.cutoff = math.cos(math.to_radians_f32(12.5))
	spot_light.outer_cutoff = math.cos(math.to_radians_f32(15))

	for !glfw.WindowShouldClose(window) {
		render()
		glfw.PollEvents()
	}
}

render :: proc() {
	current_frame_time = glfw.GetTime()
	delta_time = current_frame_time - last_frame_time
	last_frame_time = current_frame_time

	gl.BindFramebuffer(gl.FRAMEBUFFER, framebuffer)
	gl.ClearColor(0.2, 0.2, 0.2, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT)
	gl.Enable(gl.DEPTH_TEST)
	draw_scene() // Render everything to a custom fb

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0) // Back to default fb
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	// Fullscreen RenderTexture
	switch current_postprocess {
	case .NONE:      use_shader(no_post_shader)
	case .SHARPEN:   use_shader(sharpen_shader)
	case .GRAYSCALE: use_shader(grayscale_shader)
	case .BLUR:      use_shader(blur_shader)
	case .EDGE:      use_shader(edge_shader)
	}
	gl.BindVertexArray(VAOs[2])
	gl.Disable(gl.DEPTH_TEST) // Has to render in front of everything
	gl.BindTexture(gl.TEXTURE_2D, tex_color_buffer)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)

	glfw.SwapBuffers(window)
}

draw_scene :: proc() {
	using math

	gl.StencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
	gl.StencilFunc(gl.ALWAYS, 1, 0xFF)
	gl.StencilMask(0xFF)

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE if wireframe else gl.FILL)

	speed := camera.speed * f32(delta_time)
	if moving_forwards do camera.pos += camera.front * speed
	if moving_backwards do camera.pos -= camera.front * speed
	if moving_left do camera.pos -= lalg.normalize(lalg.cross(camera.front, camera.up)) * speed
	if moving_right do camera.pos += lalg.normalize(lalg.cross(camera.front, camera.up)) * speed
	if moving_up do camera.pos.y += 0.1
	if moving_down do camera.pos.y -= 0.1

	view_mat := lalg.matrix4_look_at_f32(
		camera.pos,
		camera.pos + camera.front,
		camera.up,
	)
	proj_mat := lalg.matrix4_perspective_f32(to_radians(camera.fov), f32(viewport[2]) / f32(viewport[3]), 0.01, 1000)

	// Textured Cube - 1st pass
	gl.StencilFunc(gl.ALWAYS, 1, 0xFF)
	gl.StencilMask(0xFF) // Enable writing to stencil
	use_shader(cube_shader)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, container_texture)
	gl.ActiveTexture(gl.TEXTURE1)
	gl.BindTexture(gl.TEXTURE_2D, container_specular)
	gl.ActiveTexture(gl.TEXTURE2)
	gl.BindTexture(gl.TEXTURE_2D, container_emission)
	set_uniform(cube_shader, "material.diffuse", 0)
	set_uniform(cube_shader, "material.specular", 1)
	set_uniform(cube_shader, "material.emission", 2)
	set_uniform(cube_shader, "view", &view_mat)
	set_uniform(cube_shader, "projection", &proj_mat)
	sin_time01 := sin(current_frame_time) * 0.5 + 0.5
	set_uniform(cube_shader, "viewPos", camera.pos)
	set_uniform(cube_shader, "material.ambient", v3{1, 0.5, 0.31})
	set_uniform(cube_shader, "material.shininess", 32.0)
	directional_light.color = v3(1)
	set_uniform(cube_shader, "dirLight.dir", directional_light.dir)
	set_uniform(cube_shader, "dirLight.ambient", directional_light.color * 0.05)
	set_uniform(cube_shader, "dirLight.diffuse", directional_light.color * 0.4)
	set_uniform(cube_shader, "dirLight.specular", v3(0.5))
	set_uniform(cube_shader, "spotLight.pos", camera.pos)
	set_uniform(cube_shader, "spotLight.dir", camera.front)
	set_uniform(cube_shader, "spotLight.ambient", v3(0))
	set_uniform(cube_shader, "spotLight.diffuse", spot_light.color)
	set_uniform(cube_shader, "spotLight.specular", spot_light.color)
	set_uniform(cube_shader, "spotLight.linear", spot_light.linear)
	set_uniform(cube_shader, "spotLight.quadratic", spot_light.quadratic)
	set_uniform(cube_shader, "spotLight.cutOff", spot_light.cutoff)
	set_uniform(cube_shader, "spotLight.outerCutOff", spot_light.outer_cutoff)
	for light, i in point_lights {
		light_str := fmt.tprintf("pointLights[%i]", i)
		set_uniform(cube_shader, fmt.tprintf("%s.pos", light_str), point_lights[i].pos)
		set_uniform(cube_shader, fmt.tprintf("%s.ambient", light_str), point_lights[i].color * 0.05)
		set_uniform(cube_shader, fmt.tprintf("%s.diffuse", light_str), point_lights[i].color * 0.8)
		set_uniform(cube_shader, fmt.tprintf("%s.linear", light_str), point_lights[i].color)
		set_uniform(cube_shader, fmt.tprintf("%s.specular", light_str), point_lights[i].linear)
		set_uniform(cube_shader, fmt.tprintf("%s.quadratic", light_str), point_lights[i].quadratic)
	}
	draw_cubes(cube_shader)

	// Textured Cube - 2nd pass - Scaled up
	gl.StencilFunc(gl.NOTEQUAL, 1, 0xFF)
	gl.StencilMask(0x00) // Disable writing to stencil buffer
	gl.Disable(gl.DEPTH_TEST)
	use_shader(single_color_shader)
	set_uniform(single_color_shader, "view", &view_mat)
	set_uniform(single_color_shader, "projection", &proj_mat)
	set_uniform(single_color_shader, "color", v3{1, 0.5, 0})
	draw_cubes(single_color_shader, 1.1)
	gl.StencilMask(0xFF)
	gl.StencilFunc(gl.ALWAYS, 0, 0xFF)
	gl.Enable(gl.DEPTH_TEST)

	// Light Cubes
	use_shader(single_color_shader)
	for light, idx in point_lights {
		model_mat := lalg.matrix4_translate_f32(light.pos)
		model_mat *= lalg.matrix4_scale_f32(0.2)
		set_uniform(single_color_shader, "model", &model_mat)
		set_uniform(single_color_shader, "color", light.color)

		gl.DrawArrays(gl.TRIANGLES, 0, 36)
	}

	// Windows
	use_shader(window_shader)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, window_texture)
	set_uniform(window_shader, "texture0", 0)
	set_uniform(window_shader, "view", &view_mat)
	set_uniform(window_shader, "projection", &proj_mat)
	// Sort windows (should be done only when camera moves, but whatever)
	slice.sort_by(windows, dist_cmp)
	gl.Disable(gl.CULL_FACE) // Need to see single plane from both sides
	for pos in windows {
		model_mat := lalg.matrix4_translate_f32(pos)
		set_uniform(window_shader, "model", &model_mat)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	}
	gl.Enable(gl.CULL_FACE) // Re-enable culling after drawing
}

// Furthest to closest
dist_cmp :: proc(i, j: v3) -> bool {
	return lalg.length2(camera.pos - i) > lalg.length2(camera.pos - j)
}

draw_cubes :: proc(shader: u32, scale: f32 = 1) {
	gl.BindVertexArray(VAOs[0])
	for pos, idx in cube_positions {
		rotate_by := f32(20 * idx)
		if idx % 3 == 0 {
			rotate_by += f32(current_frame_time * 2)
		}
		model_mat := lalg.matrix4_translate_f32(pos)
		model_mat *= lalg.matrix4_rotate_f32(rotate_by, {1, 0.3, 0.5})
		model_mat *= lalg.matrix4_scale_f32(scale)
		set_uniform(shader, "model", &model_mat)

		gl.DrawArrays(gl.TRIANGLES, 0, 36)
	}
}

fb_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Implicit context needs to be set explicitly for "c" procs
	// if inside it we're calling non-c procs (render in this case)
	context = runtime.default_context()

	gl.Viewport(0, 0, width, height)
	gl.GetIntegerv(gl.VIEWPORT, &viewport[0]);
	render() // Render while resizing
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	switch action {
		case glfw.PRESS:
			switch key {
			case glfw.KEY_X: wireframe = !wireframe
			case glfw.KEY_W: moving_forwards = true
			case glfw.KEY_S: moving_backwards = true
			case glfw.KEY_A: moving_left = true
			case glfw.KEY_D: moving_right = true
			case glfw.KEY_Q: moving_down = true
			case glfw.KEY_E: moving_up = true
			case glfw.KEY_1: current_postprocess = .NONE
			case glfw.KEY_2: current_postprocess = .SHARPEN
			case glfw.KEY_3: current_postprocess = .GRAYSCALE
			case glfw.KEY_4: current_postprocess = .BLUR
			case glfw.KEY_5: current_postprocess = .EDGE
			case glfw.KEY_ESCAPE: glfw.SetWindowShouldClose(window, true)
			}
		
		case glfw.RELEASE:
			switch key {
			case glfw.KEY_W: moving_forwards = false
			case glfw.KEY_S: moving_backwards = false
			case glfw.KEY_A: moving_left = false
			case glfw.KEY_D: moving_right = false
			case glfw.KEY_Q: moving_down = false
			case glfw.KEY_E: moving_up = false
			}
	}
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
	using math

	x32 := f32(x)
	y32 := f32(y)

	if first_mouse {
		last_mouse_pos = {x32, y32}
		first_mouse = false
	}
	
	offset := v2{
		x32 - last_mouse_pos.x,
		y32 - last_mouse_pos.y,
	}
	last_mouse_pos = {x32, y32}

	sensitivity: f32 = 0.1
	offset *= sensitivity

	camera.yaw += offset.x
	camera.pitch -= offset.y
	camera.pitch = clamp(camera.pitch, -89, 89)

	camera.dir = {
		cos(to_radians(camera.yaw)) * cos(to_radians(camera.pitch)),
		sin(to_radians(camera.pitch)),
		sin(to_radians(camera.yaw)) * cos(to_radians(camera.pitch)),
	}
	camera.front = lalg.normalize(camera.dir)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	camera.fov -= f32(y_offset)
	camera.fov = clamp(camera.fov, 1, 45)
}
