package sierpinski

import "core:os"
import "core:fmt"
import "core:time"
import "core:strconv"
import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////////////////////
// Main loop driver
///////////////////////////////////////////////////////////////////////////////////////////////

main :: proc() { using rl
	gui      := create_gui_entity()       //gui default struct
	triangle := create_triangle_entity()  //triangle default struct
	help     := get_args(&triangle, &gui) //get cli args
	if !help {
		init(&triangle) //all inits - screen, triangle, color, style
		defer CloseWindow()
		for !WindowShouldClose() {
			//all non-drawing stuff here
			get_user_input(&triangle, &gui) //more responsive outside draw
			rotate_triangle(&triangle)
			move_triangle(&triangle)
			lerp_color(&triangle)
			//all drawing stuff here
			BeginDrawing(); defer EndDrawing()
			ClearBackground(BLACK)
			sierpinski(&triangle)            //recurse and draw to depth
			draw_gui_zorder(&gui, &triangle) //draw gui(s) if enabled
			free_all(context.temp_allocator) //keep temp_allocator trimmed each frame (fmt.ctprintf uses this)
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Command line input procedures
///////////////////////////////////////////////////////////////////////////////////////////////

print_usage :: proc() { using fmt; using time

	printfln("%-16s%s", ODIN_BUILD_PROJECT_NAME + " by:", "xuul the terror dog")

	buf: [MIN_YYYY_DATE_LEN]u8
	printfln("%-16s%s", "Compile Date:",   to_string_yyyy_mm_dd(now(), buf[:]))
	printfln("%-16s%s", "Odin Version:",   ODIN_VERSION)
	printfln("%-16s%s", "Raylib Version:", rl.VERSION)
	printfln("%-16s%s", "Raygui Version:", rl.RAYGUI_VERSION)

	printfln("\n%s\n", "Only values within default ranges will be set, else internal defaults are used.")

	printfln("%-15s%-4s%s", "-help", "-h", "prints this help message")
	printfln("%-15s%-4s%-43s%s", "-triangle size", "-s", "size in height of triangle", "range: float = 81.0 : screen height - 81.0")
	printfln("%-15s%-4s%-43s%s", "-depth",         "-d", "sierpinski depth", "range: int = 0 : 9")
	printfln("%-15s%-4s%-43s%s", "-colorspeed",    "-c", "color change speed", "range: float = 0.0 : 1.0")
	printfln("%-15s%-4s%-43s%s", "-roaceangle",   "-a", "enables roacion and sets speed/direction", "range: float = -6.0 : 6.0")
	printfln("%-15s%-4s%-43s%s", "-bouncespeed",   "-b", "enables bounce and sets speed", "range: float = 0.0 : 10.0")
	printfln("%-15s%-4s%-43s%s", "-colormode",     "-m", "sets color mode", "default = same - values: same, mixed, or grad")
	printfln("%-15s%-4s%-43s%s", "-legend",        "-l", "enables/disables display of controls info", "default = true")
	printfln("%-15s%-4s%-43s%s", "-ui",            "-u", "enables/disables display of main ui", "default = true")
	printfln("%-15s%-4s%-43s%s", "-wireframe",     "-w", "enables/disables drawing solid", "default = false")
	printfln("%-15s%-4s%-43s%s", "-inverted",      "-i", "enables/disables drawing inverted", "default = false")
}

get_args :: proc(t: ^Triangle_Entity, g: ^Gui_Entity) -> (help: bool) { using strconv; using os
	for arg, idx in args {
		if arg == "-help" || arg == "-h" { print_usage(); return true }
		if idx + 1 < len(args) {
			switch arg { //only set the value if inside range limits
			case "-trianglesize", "-s":
				input, ok := parse_f32(args[idx+1])
				if ok && (input >= 81 || input <= f32(rl.GetRenderHeight()) - 81) { t.height = input }
			case "-depth", "-d":
				input, ok := parse_uint(args[idx+1])
				if ok && (input >= 0 || input <= 9) { t.depth = u8(input) }
			case "-colorspeed", "-c":
				input, ok := parse_f32(args[idx+1])
				if ok && (input >= 0.000 || input <= 1.000) { t.color_speed = input }
			case "-roaceangle", "-a":
				input, ok := parse_f32(args[idx+1])
				if ok && (input >= -6.000 || input <= 6.000) { t.move_aor = input; t.flags += {.ROTATE} }
			case "-bouncespeed", "-b":
				input, ok := parse_f32(args[idx+1])
				if ok && (input >= 0.000 || input <= 10.000) { t.move_speed = input; t.flags += {.BOUNCE} }
			case "-colormode", "-m":
				input := args[idx+1]
				if input == "same"  { t.color_mode = .SAME }
				if input == "mixed" { t.color_mode = .MIXED }
				if input == "grad"  { t.color_mode = .GRAD }
			case "-legend", "-l":
				input := args[idx+1]
				if input == "true"  { g.legend.flags -= {.CLOSE} }
				if input == "false" { g.legend.flags += {.CLOSE} }
			case "-ui", "-u":
				input := args[idx+1]
				if input == "true"  { g.main.flags -= {.CLOSE} }
				if input == "false" { g.main.flags += {.CLOSE} }
			case "-wireframe", "-w":
				input := args[idx+1]
				if input == "true"  { t.flags += {.WIREFRAME} }
				if input == "false" { t.flags -= {.WIREFRAME} }
			case "-inverted", "-i":
				input := args[idx+1]
				if input == "true"  { t.flags += {.INVERTED} }
				if input == "false" { t.flags -= {.INVERTED} }
			}
		}
	}
	return false
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Initialization procedures to execute before first drawing loop
///////////////////////////////////////////////////////////////////////////////////////////////

//all the inits
init :: proc(t: ^Triangle_Entity) { init_screen(); init_triangle(t); init_color(t); init_gui_style() }

//create window
init_screen :: proc() { using rl
	SetConfigFlags({.FULLSCREEN_MODE, .MSAA_4X_HINT})
	InitWindow(0, 0, "Sierpinski 2D")
	SetTargetFPS(60)
}

// h = ( s * sqrt(3) ) / 2 || s = ( 2 * h ) / sqrt(3) -- 2 from top and bottom
// reusable init for when triangle is reset by user in gui or keyboard controls
init_triangle :: proc(t: ^Triangle_Entity) { using rl
	screen_width, screen_height := f32(GetRenderWidth()), f32(GetRenderHeight())
	t.height = clamp(t.height, 81, screen_height - 81)
	t.v0 = {(screen_width / 2), (screen_height - t.height) / 2}
	t.v1 = {(screen_width / 2) - ((t.height) / sqrt(f32(3))), t.height + ((screen_height - t.height) / 2)}
	t.v2 = {(screen_width / 2) + ((t.height) / sqrt(f32(3))), t.height + ((screen_height - t.height) / 2)}
}

// reusable init for when color mode is changed by user in gui or keyboard controls
init_color :: proc(t: ^Triangle_Entity) { using rl
	t.color_options = "SAME;MIXED;GRAD"
	switch t.color_mode {
	case .SAME:
		new_start, new_end := get_random_color(), get_random_color()
		for &tcd in t.color { tcd.start, tcd.end = new_start, new_end }
	case .MIXED:
		for &tcd in t.color { tcd.start, tcd.end = get_random_color(), get_random_color() }
	case .GRAD:
		new_start, new_end, next_start, next_end := get_random_color(), get_random_color(), get_random_color(), get_random_color()
		for &tcd, i in t.color {
			tcd.current = ColorLerp(new_start, new_end, f32(i) * .111111) //start color gradient
			tcd.start = tcd.current
			tcd.end = ColorLerp(next_start, next_end, f32(i) * .111111) //next color gradient
		}
	}
}

// This is messy, but I couldn't find a better way forward without alot of trial and error
// Style behaviour seems inconsistant and many elements seem to overlap
// This is trimmed to only what I wanted after trial and error
init_gui_style :: proc() { using rl
	GDP :: rl.GuiDefaultProperty
	GCP :: rl.GuiControlProperty

	//Global Default Properties
	GuiSetStyle(.DEFAULT, i32(GDP.TEXT_SIZE), 20)
	GuiSetStyle(.DEFAULT, i32(GDP.TEXT_SPACING), 4)
	GuiSetStyle(.DEFAULT, i32(GDP.LINE_COLOR), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GDP.BACKGROUND_COLOR), ctoi32(BLACKALPHA))
	GuiSetStyle(.DEFAULT, i32(GDP.TEXT_LINE_SPACING), 2)
	GuiSetStyle(.DEFAULT, i32(GDP.TEXT_ALIGNMENT_VERTICAL), 1)

	//Default Control Properties
	GuiSetStyle(.DEFAULT, i32(GCP.BORDER_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BORDER_COLOR_FOCUSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BORDER_COLOR_PRESSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BORDER_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BASE_COLOR_NORMAL),   ctoi32(BLACKALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BASE_COLOR_FOCUSED),  ctoi32(GRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BASE_COLOR_PRESSED),  ctoi32(GRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BASE_COLOR_DISABLED), ctoi32(BLACKALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_COLOR_NORMAL),   ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_COLOR_FOCUSED),  ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_COLOR_PRESSED),  ctoi32(GRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DEFAULT, i32(GCP.BORDER_WIDTH), 1)
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_PADDING), 10)
	GuiSetStyle(.DEFAULT, i32(GCP.TEXT_ALIGNMENT), 0)

	//Buttons
	GuiSetStyle(.BUTTON, i32(GCP.BORDER_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BORDER_COLOR_FOCUSED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BORDER_COLOR_PRESSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BORDER_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BASE_COLOR_NORMAL), ctoi32(BLACKALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BASE_COLOR_FOCUSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BASE_COLOR_PRESSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BASE_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.TEXT_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.TEXT_COLOR_FOCUSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.TEXT_COLOR_PRESSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.BUTTON, i32(GCP.BORDER_WIDTH), 1)
	GuiSetStyle(.BUTTON, i32(GCP.TEXT_ALIGNMENT), 1)

	//Spinner
	GuiSetStyle(.SPINNER, i32(GuiSpinnerProperty.SPIN_BUTTON_SPACING), 2)

	//Slider
	GuiSetStyle(.SLIDER, i32(GCP.BASE_COLOR_PRESSED), ctoi32(DARKGRAYALPHA)) //bug?: actually NORMAL for button
	GuiSetStyle(.SLIDER, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.SLIDER, i32(GCP.BORDER_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))

	//Color Picker
	GuiSetStyle(.COLORPICKER, i32(GCP.BORDER_COLOR_NORMAL), ctoi32(BLACKALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.BORDER_COLOR_FOCUSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.BORDER_COLOR_PRESSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.BORDER_COLOR_DISABLED), ctoi32(BLACKALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.TEXT_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.TEXT_COLOR_FOCUSED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.TEXT_COLOR_PRESSED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.COLORPICKER, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.COLORPICKER, i32(GuiColorPickerProperty.COLOR_SELECTOR_SIZE), 4)

	//Dropdown Box
	GuiSetStyle(.DROPDOWNBOX, i32(GCP.TEXT_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.DROPDOWNBOX, i32(GCP.TEXT_COLOR_FOCUSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.DROPDOWNBOX, i32(GCP.TEXT_COLOR_PRESSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.DROPDOWNBOX, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))

	//Toggle Slider
	GuiSetStyle(.TOGGLE, i32(GCP.BORDER_COLOR_NORMAL), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BORDER_COLOR_FOCUSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BORDER_COLOR_PRESSED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BORDER_COLOR_DISABLED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BASE_COLOR_NORMAL), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BASE_COLOR_FOCUSED), ctoi32(DARKGRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BASE_COLOR_PRESSED), ctoi32(GRAYALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.BASE_COLOR_DISABLED), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.TEXT_COLOR_NORMAL), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.TEXT_COLOR_FOCUSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.TEXT_COLOR_PRESSED), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.TEXT_COLOR_DISABLED), ctoi32(BLACKALPHA))
	GuiSetStyle(.TOGGLE, i32(GCP.TEXT_ALIGNMENT), 1)
}
