// 1. Hello Window
// https://learnopengl.com/Getting-started/Hello-Window

package main

import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:glfw"

main :: proc() {
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	// Only for macOS
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)

	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Hi mom!", nil, nil)
	if window == nil {
		fmt.print("Failed to create GLFW window\n")
		glfw.Terminate()
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

	// This does what gladLoadGLLoader() would do
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, glfw.gl_set_proc_address)
	fmt.print(gl.GetString(gl.VERSION))

	for !glfw.WindowShouldClose(window) {
		process_input(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		glfw.PollEvents()
		glfw.SwapBuffers(window)
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}
