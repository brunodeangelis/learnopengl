package main

import "core:os"
import "core:strings"
import "core:path/filepath"
import lalg "core:math/linalg"

import gl "vendor:OpenGL"

load_shader :: proc(name: string) -> (program: u32, success: bool) {
	file_name, concat_err := strings.concatenate({name, ".", SHADERS_EXTENSION})
	if concat_err != nil {
		return 0, false
	}
	defer delete(file_name)

	file_path := filepath.join({SHADERS_BASE_PATH, file_name})
	file := os.read_entire_file_from_filename(file_path) or_return
	defer delete(file)

	splits := [?]string {SHADERS_VERTEX_SEPARATOR, SHADERS_FRAGMENT_SEPARATOR}
	sections, split_err := strings.split_multi(string(file), splits[:])
	if split_err != nil {
		return 0, false
	}
	defer delete(sections)

	// See proc code in odin/vendor/OpenGL for details
	return gl.load_shaders_source(sections[1], sections[2])
}

use_shader :: proc(id: u32) {
	gl.UseProgram(id)
}

get_uniform_loc :: proc(program: u32, uniform: string) -> i32 {
	return gl.GetUniformLocation(program, cstring(raw_data(uniform)))
}

set_uniform_int :: proc(program: u32, uniform: string, value: int) {
	gl.Uniform1i(get_uniform_loc(program, uniform), i32(value))
}

set_uniform_f32 :: proc(program: u32, uniform: string, value: f32) {
	gl.Uniform1f(get_uniform_loc(program, uniform), value)
}

set_uniform_v4 :: proc(program: u32, uniform: string, value: v4) {
	gl.Uniform4f(
		get_uniform_loc(program, uniform),
		value.x, value.y, value.z, value.w
	)
}

set_uniform_mat4 :: proc(program: u32, uniform: string, value: ^mat4) {
	gl.UniformMatrix4fv(
		get_uniform_loc(program, uniform), 1, gl.FALSE, &value[0][0]
	)
}

set_uniform :: proc{set_uniform_int, set_uniform_f32, set_uniform_v4, set_uniform_mat4}
