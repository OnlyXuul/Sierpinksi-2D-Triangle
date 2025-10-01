package sierpinski

import "core:os"
import "core:fmt"
import "core:time"
import "core:strconv"
import rl "vendor:raylib"

main :: proc() { using rl
  gui      := createGuis()
  triangle := createTriangle()
  help := getArgs(&triangle, &gui)
  if !help {
    init(&triangle) //all inits - screen, triangle, color, style
    defer CloseWindow()
    for !WindowShouldClose() {
      getUserInput(&triangle, &gui) //more responsive before draw
      rotateTriangle(&triangle)
      bounceTriangle(&triangle)
      lerpColor(&triangle) 
      BeginDrawing(); defer EndDrawing()
      ClearBackground(BLACK)
      sierpinski(&triangle)       //recurse to max_depth
      drawZOrder(&gui, &triangle) //draw gui(s) if enabled
    }
  }
}

printUsage :: proc() { using fmt; using time
  buf: [MIN_YYYY_DATE_LEN]u8
  printfln("%v by xuul the terror dog\n", ODIN_BUILD_PROJECT_NAME)
  printfln("%-16s%v",   "compile date:", to_string_yyyy_mm_dd(now(), buf[:]))
  printfln("%-16s%v",   "odin version:", ODIN_VERSION)
  printfln("%-16s%v",   "raylib version:", rl.VERSION)
  printfln("%-16s%v\n", "raygui version:", rl.RAYGUI_VERSION)

  println("Only values within default ranges will be set, else defaults are used")
  printfln("%-15s%-4s%s", "-help", "-h", "prints this help message")
  printfln("%-15s%-4s%-43s%s", "-triangle size", "-s", "size in height of triangle", "range: float = 81.0 : screen height - 81.0")
  printfln("%-15s%-4s%-43s%s", "-depth",         "-d", "sierpinski depth", "range: int = 0 : 9")
  printfln("%-15s%-4s%-43s%s", "-colorspeed",    "-c", "color change speed", "range: float = 0.0 : 1.0")
  printfln("%-15s%-4s%-43s%s", "-rotateangle",   "-a", "enables rotation and sets speed/direction", "range: float = -6.0 : 6.0")
  printfln("%-15s%-4s%-43s%s", "-bouncespeed",   "-b", "enables bounce and sets speed", "range: float = 0.0 : 10.0")
  printfln("%-15s%-4s%-43s%s", "-colormode",     "-m", "sets color mode", "default = same - values: same, mixed, or grad")
  printfln("%-15s%-4s%-43s%s", "-legend",        "-l", "enables/disables display of controls info", "default = true")
  printfln("%-15s%-4s%-43s%s", "-ui",            "-u", "enables/disables display of main ui", "default = true")
  printfln("%-15s%-4s%-43s%s", "-wireframe",     "-w", "enables/disables drawing solid", "default = true")
  printfln("%-15s%-4s%-43s%s", "-inverted",      "-i", "enables/disables drawing inverted", "default = true")
}

getArgs :: proc(t: ^SEntity, g: ^GEntity) -> (help: bool) { using strconv; using os
  for arg, idx in args {
    if arg == "-help" || arg == "-h" { printUsage(); return true }
    if idx + 1 < len(args) {
      switch arg { //only set the value if inside range limits
      case "-trianglesize", "-s":
        input := f32(atoi(args[idx+1]))
        if input >= 81 || input <= t.screen.y - 81 { t.height = input }
      case "-depth", "-d":
        input := u8(atoi(args[idx+1]))
        if input >= 0 || input <= 9 { t.depth = input }
      case "-colorspeed", "-c":
        input := f32(atof(args[idx+1]))
        if input >= 0.0 || input <= 1.0 { t.color.speed = input }
      case "-rotateangle", "-a":
        input := f32(atof(args[idx+1]))
        if input >= -6.0 || input <= 6.0 { t.move.a_o_r = input; t.states += {.ROTATE} }
      case "-bouncespeed", "-b":
        input := f32(atof(args[idx+1]))
        if input >= 0.0 || input <= 10.0 { t.move.speed = input; t.states += {.BOUNCE} }
      case "-colormode", "-m":
        input := args[idx+1]
        if input == "same"  { t.color.mode.e = .SAME }
        if input == "mixed" { t.color.mode.e = .MIXED }
        if input == "grad"  { t.color.mode.e = .GRAD }
      case "-legend", "-l":
        input := args[idx+1]
        if input == "true"  { g.states -= {.CWBCLOSE} }
        if input == "false" { g.states += {.CWBCLOSE} }
      case "-ui", "-u":
        input := args[idx+1]
        if input == "true"  { g.states -= {.MWBCLOSE} }
        if input == "false" { g.states += {.MWBCLOSE} }
      case "-wireframe", "-w":
        input := args[idx+1]
        if input == "true"  { t.states += {.WIREFRAME} }
        if input == "false" { t.states -= {.WIREFRAME} }
      case "-inverted", "-i":
        input := args[idx+1]
        if input == "true"  { t.states += {.INVERTED} }
        if input == "false" { t.states -= {.INVERTED} }
      }
    }
  }
  return false
}

//all the inits
init :: proc(t: ^SEntity) { initScreen(); initTriangle(t); initColor(t); initGuiStyle() }

//create window
initScreen :: proc() { using rl
  SetConfigFlags({.FULLSCREEN_MODE, .MSAA_4X_HINT})
  InitWindow(0, 0, "Sierpinski 2D")
  SetTargetFPS(60)
}

// h = ( s * sqrt(3) ) / 2 || s = ( 2 * h ) / sqrt(3) -- 2 from top and bottom
//reusable init for when triangle is reset by user
initTriangle :: proc(t: ^SEntity) { using rl
  t.screen = {f32(GetRenderWidth()), f32(GetRenderHeight())}
  if t.height == 0 {t.height = t.screen.y - 81 }
  if t.height > t.screen.y - 81 { t.height = t.screen.y - 81}
  if t.height < 81 { t.height = 81 }
  t.v = {
    {(t.screen.x / 2), (t.screen.y - t.height) / 2}, //v1
    {(t.screen.x / 2) - ((t.height) / sqrt(f32(3))), t.height + ((t.screen.y - t.height) / 2)}, //v2
    {(t.screen.x / 2) + ((t.height) / sqrt(f32(3))), t.height + ((t.screen.y - t.height) / 2)}  //v3
  }
}

//reusable init for when color mode is changed by user
initColor :: proc(t: ^SEntity) { using rl
  t.color.options = "SAME;MIXED;GRAD"
  switch t.color.mode.e {
  case .SAME:
    new_start, new_end := getRandomColor(), getRandomColor()
    for &tcd in t.color.depth { tcd.start, tcd.end = new_start, new_end }
  case .MIXED:
    for &tcd in t.color.depth { tcd.start, tcd.end = getRandomColor(), getRandomColor() }
  case .GRAD:
    new_start, new_end, next_start, next_end := getRandomColor(), getRandomColor(), getRandomColor(), getRandomColor()
    for &tcd, i in t.color.depth {
      tcd.current = ColorLerp(new_start, new_end, f32(i) * .111111) //start color gradient
      tcd.start = tcd.current
      tcd.end = ColorLerp(next_start, next_end, f32(i) * .111111) //next color gradient
    }
  }
}

//this is messy, but I couldn't find a better way forward without alot of trial and error
//style behaviour seems inconsistant and many elements seem to overlap
//This is trimmed to only what I wanted after trial and error
initGuiStyle :: proc() { using rl
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