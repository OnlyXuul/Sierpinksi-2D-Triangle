package sierpinski

import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////
// Input control (mouse and keyboard)
// Some special cases for gui windows
///////////////////////////////////////////////////////////////////////////////

get_user_input :: proc(t: ^Triangle_Entity, g: ^Gui_Entity) { using rl

	//Mouse input
	mpos := GetMousePosition()
	//hide curser if all gui(s) are closed - show if they are enabled again by key press
	if .CLOSE in g.main.flags && .CLOSE in g.legend.flags && .CLOSE in g.about.flags { HideCursor() } else { ShowCursor() }

   //move windows and set z-order under some sane conditions
	if IsMouseButtonPressed(.LEFT) {
		//set z-order if mouse clicks in window and is not under another window
		if is_mouse_exclusive(mpos, g.main,   g.legend, g.about)  { set_gui_zorder_top(g, draw_main) }   //z-order check and set
		if is_mouse_exclusive(mpos, g.legend, g.main,   g.about)  { set_gui_zorder_top(g, draw_legend) } //z-order check and set
		if is_mouse_exclusive(mpos, g.about,  g.main,   g.legend) { set_gui_zorder_top(g, draw_about) }  //z-order check and set

		//check for and enable window move using title bar - excludes titlebar button rects using tooltip locations
		top_z := g.zorder[len(g.zorder)-1]
		if is_mouse_exclusive(mpos, {g.main.x, g.main.y + 2, g.main.width, 24},
			g.main.tooltip[.TT_CLOSE].loc,
			g.main.tooltip[.TT_TOGGLELEGEND].loc,
			g.main.tooltip[.TT_TOGGLEABOUT].loc) &&
			top_z == draw_main { g.main.flags += {.MOVE} }
		if is_mouse_exclusive(mpos, {g.legend.x, g.legend.y + 2, g.legend.width, 24},
			g.legend.tooltip[.TT_CLOSE].loc,
			g.legend.tooltip[.TT_CLOSE].loc) &&
			top_z == draw_legend { g.legend.flags += {.MOVE} }
		if is_mouse_exclusive(mpos, {g.about.x, g.about.y + 2, g.about.width, 24},
			g.about.tooltip[.TT_CLOSE].loc) && top_z == draw_about { g.about.flags += {.MOVE} }
	}
  
	if .MOVE in g.main.flags { //move main window box
		move_gui(&g.main)
		update_main_grid(g)
	}
	if .MOVE in g.legend.flags { //move controls window box
		move_gui(&g.legend)
		update_legend_grid(g)
	}
	if .MOVE in g.about.flags { //move about window box
		move_gui(&g.about)
	}
	if IsMouseButtonUp(.LEFT) { //disable moves
		g.main.flags   -= {.MOVE}
		g.legend.flags -= {.MOVE}
		g.about.flags  -= {.MOVE}
	}

	//Keyboard input
	for key := GetKeyPressed(); key > .KEY_NULL; key = GetKeyPressed() {
		#partial switch key {
		case .T:
			t.flags -= {.ROTATE, .BOUNCE, .WIREFRAME, .INVERTED}
			t.flags += {.PAUSECOLOR}
			init_triangle(t) //reset triangle
		case .R:
			if IsKeyDown(.LEFT_CONTROL) { t.move_aor *= -1 } else { t.flags ~= {.ROTATE} } //toggle rotation
		case .P:
			t.flags ~= {.PAUSECOLOR} //pause color lerping
		case .W:
			t.flags ~= {.WIREFRAME} //toggle solid triangles
		case .I:
			t.flags ~= {.INVERTED} //toggle inverted triangles
		case .M:
			t.color_mode = Triangle_Color_Mode((i32(t.color_mode) + 1) % 3)
			init_color(t) //cycle color modes
		case .L, .C:
			g.legend.flags ~= {.CLOSE} //toggle legend display - allow also C since I keep trying to use that one
			if .CLOSE not_in g.legend.flags { set_gui_zorder_top(g, draw_legend) }
			else { set_gui_zorder_bottom(g, draw_legend) }
		case .U:
			g.main.flags ~= {.CLOSE} //toggle main UI
			if .CLOSE not_in g.main.flags { set_gui_zorder_top(g, draw_main) }
			else { set_gui_zorder_bottom(g, draw_main) }
		case .B:
			t.flags ~= {.BOUNCE} //toggle bounce
		case .ZERO..=.NINE:
			t.depth = u8(key) - 48 //set triangle depth
		case .UP:
			modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
			if !modifier_keys { t.color_speed = t.color_speed + 0.020 > 1 ? 1 : t.color_speed + 0.020 } //increase color lerp speed
			if IsKeyDown(.LEFT_SHIFT) { t.move_speed = t.move_speed + 0.050 > 10 ? 10 : t.move_speed + 0.05 } //increase bounce speed
			if IsKeyDown(.LEFT_ALT) && IsKeyDown(.UP) {scale_triangle(t, 1.020) } //increase triangle size
			if IsKeyDown(.LEFT_CONTROL) { //increase rotation angle
					rotate_angle_abs := abs(t.move_aor)
					if t.move_aor < 0 { t.move_aor = (rotate_angle_abs + 0.050) * -1}
					else { t.move_aor = rotate_angle_abs + 0.050 }
			}
		case .DOWN:
			modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
			if !modifier_keys { t.color_speed = t.color_speed - 0.020 < 0 ? 0 : t.color_speed - 0.020 } //decrease color lerp speed
			if IsKeyDown(.LEFT_SHIFT) { t.move_speed = t.move_speed - 0.050 < 0 ? 0 : t.move_speed - 0.050 } //decrease bounce speed
			if IsKeyDown(.LEFT_ALT) && IsKeyDown(.DOWN) { scale_triangle(t, 0.980) } //decrease triangle size
			if IsKeyDown(.LEFT_CONTROL) { //decrease rotation angle
				rotate_angle_abs := abs(t.move_aor)
				if t.move_aor < 0 { t.move_aor = (rotate_angle_abs - 0.050) * -1}
				else { t.move_aor = rotate_angle_abs - 0.050 }
			}
		}
	}
}

move_gui :: proc(r: ^rl.Rectangle) { using rl
	mouse_delta := GetMouseDelta()
	screen := [2]f32{f32(GetRenderWidth()), f32(GetRenderHeight())}

	r.x = clamp(r.x + mouse_delta.x, 0, screen.x - r.width)
	r.y = clamp(r.y + mouse_delta.y, 0, screen.y - r.height)
}
