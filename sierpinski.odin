package sierpinski

import "core:math"
import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////////////////////
// Triangle_Entity - contains all triangle data
///////////////////////////////////////////////////////////////////////////////////////////////

Triangle_Entity :: struct {
	using v: Triangle,
	using _: Triangle_Move,
	using _: Triangle_Color,
	flags:   bit_set[Triangle_Flags],
	depth:   u8,
	height:  f32,
}

Triangle :: struct {
	v0: rl.Vector2,
	v1: rl.Vector2,
	v2: rl.Vector2,
}

Triangle_Move :: struct {
	move_aor:       f32, //angle of rotation
	move_speed:     f32,
	move_direction: bit_set[Triangle_Move_Direction],
}

Triangle_Move_Direction :: enum {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

Triangle_Color :: struct {
	color:           [10]Triangle_Depth_Color,
	color_mode:      Triangle_Color_Mode,
	color_options:   cstring,
	color_speed:     f32,
	color_lerp_time: f32,
}

Triangle_Depth_Color :: struct {
	start:   rl.Color,
	end:     rl.Color,
	current: rl.Color,
}

Triangle_Color_Mode :: enum {
	SAME,
	MIXED,
	GRAD,
}

Triangle_Flags :: enum u8 {
	BOUNCE,
	ROTATE,
	WIREFRAME,
	INVERTED,
	PAUSECOLOR,
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Triangle default constructor
///////////////////////////////////////////////////////////////////////////////////////////////

create_triangle_entity :: proc() -> (triangle: Triangle_Entity) {
	triangle = {
		depth  = 4,
		height = 600.000,
		move_speed = 4.000,
		move_direction = {.LEFT, .UP},
		move_aor = 0.250,
		color_mode = .GRAD,
		color_speed = 0.100,
	}
	return
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Sierpinksi triangle procedures
///////////////////////////////////////////////////////////////////////////////////////////////

//overload - choose inverted or standard
sierpinski :: proc(t: ^Triangle_Entity) { if .INVERTED in t.flags { sierpinski_inverted(t, t, 0) } else { sierpinski_standard(t, t, 0) } }

//inverted draws the inner (center) upside-down triangle at each depth, with a few special cases for flavor
sierpinski_inverted :: proc(t: ^Triangle_Entity, s: Triangle, curr_depth: u8) { using rl
	//some aliases for readability
	color      := t.color[curr_depth].current
	wire_frame := .WIREFRAME in t.flags ? true : false
	max_depth  := t.depth

	//special cases without inverted vectors
	if max_depth == 0 && !wire_frame { DrawTriangle(s.v0, s.v1, s.v2, t.color[0].current) }
	if curr_depth == 0 { DrawTriangleLines(s.v0, s.v1, s.v2, t.color[0].current) }

	//invert vectors
	if  wire_frame && curr_depth > 0 { DrawTriangleLines((s.v0 + s.v1) / 2, (s.v1 + s.v2) / 2, (s.v2 + s.v0) / 2, color) }
	if !wire_frame && curr_depth > 0 { DrawTriangle((s.v0 + s.v1) / 2, (s.v1 + s.v2) / 2, (s.v2 + s.v0) / 2, color) }

	//recurse to max_depth - ignore curr_depth == 0 for special cases - handled below
	if curr_depth != 0 && curr_depth + 1 <= max_depth {
		sierpinski_inverted(t, {s.v0, (s.v0 + s.v1) / 2, (s.v0 + s.v2) / 2}, curr_depth + 1) //top   v0' = (v0+v0)/2, (v0+v1)/2, (v0+v2)/2
		sierpinski_inverted(t, {(s.v1 + s.v0) / 2, s.v1, (s.v1 + s.v2) / 2}, curr_depth + 1) //left  v1' = (v1+v0)/2, (v1+v1)/2, (v1+v2)/2
		sierpinski_inverted(t, {(s.v2 + s.v0) / 2, (s.v2 + s.v1) / 2, s.v2}, curr_depth + 1) //right v2' = (v2+v0)/2, (v2+v1)/2, (v2+v2)/2
	}

	//re-entry into recursion from special cases ignored by curr_depth != 0 above
	if curr_depth == 0 && max_depth > 0 { sierpinski_inverted(t, s, 1) }
}

//standard method - draw top, left, and right corners at each depth with some exceptions for flavor
sierpinski_standard :: proc(t: ^Triangle_Entity, s: Triangle, curr_depth: u8) { using rl
	//not inverted - draw from 0 to t.depth
	color: = t.color[curr_depth].current

	if .WIREFRAME in t.flags {
		sierpinski_inverted(t, s, 0)
	}

	if .WIREFRAME not_in t.flags {
		#partial switch t.color_mode {
			case .SAME:
				if t.depth == 0 { DrawTriangle(s.v0, s.v1, s.v2, color) }
				else if curr_depth % 2 == t.depth % 2 { DrawTriangle(s.v0, s.v1, s.v2, BLACK); DrawTriangleLines(s.v0, s.v1, s.v2, color) }
				else { DrawTriangle(s.v0, s.v1, s.v2, color) }
			case:
				DrawTriangle(s.v0, s.v1, s.v2, color)
		}
		if curr_depth + 1 <= t.depth { //recurse to t.depth
			sierpinski_standard(t, {s.v0, (s.v0 + s.v1) / 2, (s.v0 + s.v2) / 2}, curr_depth + 1) //top   v0' = (v0+v0)/2, (v0+v1)/2, (v0+v2)/2
			sierpinski_standard(t, {(s.v1 + s.v0) / 2, s.v1, (s.v1 + s.v2) / 2}, curr_depth + 1) //left  v1' = (v1+v0)/2, (v1+v1)/2, (v1+v2)/2
			sierpinski_standard(t, {(s.v2 + s.v0) / 2, (s.v2 + s.v1) / 2, s.v2}, curr_depth + 1) //right v2' = (v2+v0)/2, (v2+v1)/2, (v2+v2)/2
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Color mode control of each depth of triangle
///////////////////////////////////////////////////////////////////////////////////////////////

lerp_color :: proc(t: ^Triangle_Entity) { using rl
	if .PAUSECOLOR not_in t.flags {
		t.color_lerp_time += GetFrameTime() * t.color_speed
		switch t.color_mode {
		case .SAME:
			if t.color_lerp_time > 1.000 { // Clamp time
				t.color_lerp_time = 0.000
				random_color := get_random_color()
				for &tcd in t.color { tcd.start = tcd.end; tcd.end = random_color }
			}
			for &tcd in t.color { tcd.current = ColorLerp(tcd.start, tcd.end, t.color_lerp_time) }
		case .MIXED:
			if t.color_lerp_time > 1.000 { // Clamp time
				t.color_lerp_time = 0.000
				for &tcd in t.color { tcd.start = tcd.end; tcd.end = get_random_color() }
			}
			for &tcd in t.color { tcd.current = ColorLerp(tcd.start, tcd.end, t.color_lerp_time) }
		case .GRAD:
			if t.color_lerp_time > 1.000 { // Clamp time
				t.color_lerp_time = 0.000
				start_color := get_random_color()
				end_color   := get_random_color()
				for &tcd, i in t.color {
					tcd.start = tcd.end
					tcd.end = ColorLerp(start_color, end_color, f32(i) * .1111111)
				}
			}
			for &tcd in t.color { tcd.current = ColorLerp(tcd.start, tcd.end, t.color_lerp_time) }
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Triangle transform procedures
///////////////////////////////////////////////////////////////////////////////////////////////

//rotate about the centroid (center of mass, not half of height)
rotate_triangle :: proc(t: ^Triangle_Entity) { using rl
	if .ROTATE in t.flags {
		centroid := (t.v0 + t.v1 + t.v2) / 3
		t.v = {
			Vector2Rotate(t.v0 - centroid, t.move_aor * DEG2RAD) + centroid,
			Vector2Rotate(t.v1 - centroid, t.move_aor * DEG2RAD) + centroid,
			Vector2Rotate(t.v2 - centroid, t.move_aor * DEG2RAD) + centroid
		}
	}
}

//using a lazy bounce, since 2 vectors can be offscreen simultaniously - no physics :(
move_triangle :: proc(t: ^Triangle_Entity) { using rl
	if .BOUNCE in t.flags {
		s, w, h := t.move_speed, f32(GetRenderWidth()), f32(GetRenderHeight())

		if t.v0.x <= 0 || t.v1.x <= 0 || t.v2.x <= 0 {
			t.move_direction += {.RIGHT}
			t.move_direction -= {.LEFT}
			if .ROTATE in t.flags { t.move_aor *= -1 }
		}
		if t.v0.x >= w || t.v1.x >= w || t.v2.x >= w {
			t.move_direction += {.LEFT}
			t.move_direction -= {.RIGHT}
			if .ROTATE in t.flags { t.move_aor *= -1 }
		}
		if t.v0.y <= 0 || t.v1.y <= 0 || t.v2.y <= 0 {
			t.move_direction += {.DOWN}
			t.move_direction -= {.UP}
			if .ROTATE in t.flags { t.move_aor *= -1 }
		}
		if t.v0.y >= h || t.v1.y >= h || t.v2.y >= h {
			t.move_direction += {.UP}
			t.move_direction -= {.DOWN}
			if .ROTATE in t.flags { t.move_aor *= -1 }
		}

		switch t.move_direction {
		case {.LEFT,  .UP}:   t.v0 += {-s, -s}; t.v1 += {-s, -s}; t.v2 += {-s, -s}
		case {.LEFT,  .DOWN}: t.v0 += {-s,  s}; t.v1 += {-s,  s}; t.v2 += {-s,  s}
		case {.RIGHT, .UP}:   t.v0 += {s,  -s}; t.v1 += {s,  -s}; t.v2 += {s,  -s}
		case {.RIGHT, .DOWN}: t.v0 += {s,   s}; t.v1 += {s,   s}; t.v2 += {s,   s}
		}
	}
}

//scale triangle based on factor of height
scale_triangle :: proc(t: ^Triangle_Entity, factor: f32) { using math
	resized: Triangle
	centroid := (t.v0 + t.v1 + t.v2) / 3
	resized.v0 = centroid + ((t.v0 - centroid) * factor)
	resized.v1 = centroid + ((t.v1 - centroid) * factor)
	resized.v2 = centroid + ((t.v2 - centroid) * factor)
	side := sqrt(pow((resized.v1.x - resized.v0.x), 2) + pow((resized.v1.y - resized.v0.y), 2))
	resized_height := floor((side * sqrt(f32(3))) / 2)
	if resized_height >= 81.000 && resized_height <= (f32(rl.GetRenderHeight()) - 81.000) {
		t.v = resized
		t.height = resized_height
	}
}
