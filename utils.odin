package main

import "core:os"
import "core:strings"
import "core:path/filepath"
import lalg "core:math/linalg"
import "core:fmt"

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"


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

set_uniform_bool :: proc(program: u32, uniform: string, value: bool) {
	gl.Uniform1i(get_uniform_loc(program, uniform), value ? 1 : 0)
}

set_uniform_int :: proc(program: u32, uniform: string, value: int) {
	gl.Uniform1i(get_uniform_loc(program, uniform), i32(value))
}

set_uniform_f32 :: proc(program: u32, uniform: string, value: f32) {
	gl.Uniform1f(get_uniform_loc(program, uniform), value)
}

set_uniform_v3 :: proc(program: u32, uniform: string, value: v3) {
	gl.Uniform3f(
		get_uniform_loc(program, uniform),
		value.x, value.y, value.z,
	)
}

set_uniform_v4 :: proc(program: u32, uniform: string, value: v4) {
	gl.Uniform4f(
		get_uniform_loc(program, uniform),
		value.x, value.y, value.z, value.w,
	)
}

set_uniform_mat4 :: proc(program: u32, uniform: string, value: ^mat4) {
	gl.UniformMatrix4fv(
		get_uniform_loc(program, uniform), 1, gl.FALSE, &value[0][0],
	)
}

set_uniform :: proc{
	set_uniform_bool,
	set_uniform_int,
	set_uniform_f32,
	set_uniform_v3,
	set_uniform_v4,
	set_uniform_mat4,
}

load_texture :: proc(file_name: string, wrap_s := gl.REPEAT, wrap_t := gl.REPEAT) -> u32 {
	tex_id: u32
	gl.GenTextures(1, &tex_id)

	image_width, image_height, image_chans: i32
	file_path_string := filepath.join({TEXTURES_BASE_PATH, file_name})
	file_path := strings.clone_to_cstring(file_path_string)
	defer delete(file_path)
	
	image_bytes := stbi.load(file_path, &image_width, &image_height, &image_chans, 0)
	defer stbi.image_free(image_bytes)	

	format := gl.RGB
	if image_chans == 4 {
		format = gl.RGBA
	}

	gl.BindTexture(gl.TEXTURE_2D, tex_id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, i32(wrap_s))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, i32(wrap_t))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	gl.TexImage2D(gl.TEXTURE_2D, 0, i32(format), i32(image_width), i32(image_height), 0, u32(format), gl.UNSIGNED_BYTE, image_bytes)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	return tex_id
}