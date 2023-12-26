package main

import lalg "core:math/linalg"

v2 :: lalg.Vector2f32
v3 :: lalg.Vector3f32
v4 :: lalg.Vector4f32

mat4 :: lalg.Matrix4f32

Camera :: struct {
    pos, target, dir, up, right, front: v3,
    speed, yaw, pitch, fov: f32,
}

Light :: struct {
	pos, color: v3,
}

Attenuation :: struct {
    linear, quadratic: f32,
}

Directional_Light :: struct {
    using light: Light,
    dir: v3,
}

Point_Light :: struct {
    using light: Light,
    using att: Attenuation,
}

Spot_Light :: struct {
    using directional_light: Directional_Light,
    using att: Attenuation,
    cutoff, outer_cutoff: f32,
}
