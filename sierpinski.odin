package sierpinski

import "core:os"
import "core:fmt"
import "core:math"
import "core:time"
import "core:strconv"
import rl "vendor:raylib"

TriangleVector2 :: struct { v1, v2, v3: rl.Vector2 }
triangle: TriangleVector2

DepthColor :: struct { start, end, color : rl.Color }
depth_color: [10]DepthColor

ColorModes :: enum { SAME, MIXED, GRAD }
color_mode_names := [ColorModes]cstring { .SAME = "SAME", .MIXED = "MIXED", .GRAD = "GRAD" }
color_mode: ColorModes = .SAME

Vector2Int  :: struct { x, y: i32 }
TextFormat2 :: struct {
  v1: Vector2Int, //set in init_text() based on render_size()
  v2: Vector2Int, //set in init_text() based on render_size()
  lh: i32,        //line height - set in init_text()
  fs: i32,        //font size - default above
  ls: i32,        //line spacing - default above
  c:  rl.Color,   // default above
}
info_format:     TextFormat2
controls_format: TextFormat2

BounceDirections :: enum { LEFT, RIGHT, UP, DOWN }
bounce_left_right : BounceDirections = .LEFT
bounce_up_down    : BounceDirections = .UP

//global control settings/defaults
max_depth:    i32  = 7
color_speed:  f32  = 0.20
rotate_angle: f32  = 0.25
bounce_speed: f32  = 1.50
bounce:       bool = false
rotate:       bool = false
controls:     bool = true
info:         bool = true
draw_solid:   bool = true
inverted:     bool = true
pause_color:  bool = false
fullscreen:   bool = false

//proc globals not backed by custom structs
render_size:     rl.Vector2
triangle_height: f32
lerp_time:       f32

main :: proc() { using rl
  help := getArgs()
  if !help {
    init()
    defer CloseWindow()
    for !WindowShouldClose() {
      getKeyPresses()
      ClearBackground(BLACK)
      BeginDrawing()
        updateText()
        sierpinsky(triangle, 0) //recurse to max_depth
      EndDrawing()
      rotateTriangle()
      bounceTriangle()
      lerpColor(color_mode)
    }
  }
}

printUsage :: proc() { using fmt; using time
  buf: [MIN_YYYY_DATE_LEN]u8
  printfln("%v by xuul the terror dog", ODIN_BUILD_PROJECT_NAME)
  printfln("compile date: %v odin version: %v\n", to_string_yyyy_mm_dd(now(), buf[:]), ODIN_VERSION)
  println("Only values within default ranges will be set, else defaults are used")
  printfln("%-15s%-4s%s", "-help", "-h", "prints this help message")
  printfln("%-15s%-4s%-43s%s", "-triangle size", "-ts", "size in height of triangle", "range: float = 81.0 : screen height - 81.0")
  printfln("%-15s%-4s%-43s%s", "-maxdepth", "-md", "sierpinski depth", "range: int = 0 : 9")
  printfln("%-15s%-4s%-43s%s", "-colorspeed", "-cs", "color change speed", "range: float = 0.0 : 1.0")
  printfln("%-15s%-4s%-43s%s", "-rotateangle", "-ra", "enables rotation and sets speed/direction", "range: float = -6.0 : 6.0")
  printfln("%-15s%-4s%-43s%s", "-bouncespeed", "-bs", "enables bounce and sets speed", "range: float = 0.0 : 10.0")
  printfln("%-15s%-4s%-43s%s", "-colormode", "-cm", "sets color mode", "default = same - values: same, mixed, or grad")
  printfln("%-15s%-4s%-43s%s", "-controls", "-c", "enables/disables display of controls info", "default = true")
  printfln("%-15s%-4s%-43s%s", "-info", "-i", "enables/disables display of info stats", "default = true")
  printfln("%-15s%-4s%-43s%s", "-drawsolid", "-ds", "enables/disables drawing solid", "default = true")
  printfln("%-15s%-4s%-43s%s", "-inverted", "-iv", "enables/disables drawing inverted", "default = true")
  printfln("%-15s%-4s%-43s%s", "-fullscreen", "-f", "enables/disables fullscreen (hides cursor)", "default = false")
}

getArgs :: proc() -> (help: bool) { using strconv; using os
  for arg, idx in args {
    if arg == "-help" || arg == "-h" {printUsage(); return true}
    if idx + 1 < len(args) {
      switch arg { //only set the value if inside range limits
      case "-trianglesize", "-ts":
        input := f32(atoi(args[idx+1]))
        if input >= 81 || input <= render_size.y - 81 { triangle_height = input }
      case "-maxdepth", "-md":
        input := i32(atoi(args[idx+1]))
        if input >= 0 || input <= 9 { max_depth = input }
      case "-colorspeed", "-cs":
        input := f32(atof(args[idx+1]))
        if input >= 0.0 || input <= 1.0 { color_speed = input }
      case "-rotateangle", "-ra":
        input := f32(atof(args[idx+1]))
        if input >= -6.0 || input <= 6.0 { rotate_angle = input; rotate = true }
      case "-bouncespeed", "-bs":
        input := f32(atof(args[idx+1]))
        if input >= 0.0 || input <= 10.0 { bounce_speed = input; bounce = true }
      case "-colormode", "-cm":
        input := args[idx+1]
        if input == "same"  { color_mode = .SAME }
        if input == "mixed" { color_mode = .MIXED }
        if input == "grad"  { color_mode = .GRAD }
      case "-controls", "-c":
        input := args[idx+1]
        if input == "true"  { controls = true }
        if input == "false" { controls = false }
      case "-info", "-i":
        input := args[idx+1]
        if input == "true"  { info = true }
        if input == "false" { info = false }
      case "-drawsolid", "-ds":
        input := args[idx+1]
        if input == "true"  { draw_solid = true }
        if input == "false" { draw_solid = false }
      case "-inverted", "-iv":
        input := args[idx+1]
        if input == "true"  { inverted = true }
        if input == "false" { inverted = false }
      case "-fullscreen", "-f":
        input := args[idx+1]
        if input == "true"  { fullscreen = true }
        if input == "false" { fullscreen = false }
      }
    }
  }
  return false
}

init :: proc() { initScreen(); initTriangleHeight(); initTriangle(); initColor(color_mode) }

initScreen :: proc() { using rl
  if fullscreen { SetConfigFlags({.FULLSCREEN_MODE}) }
  else { SetConfigFlags({.WINDOW_UNDECORATED, .BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED}) }
  InitWindow(0, 0, "Sierpinski 2D")
  SetTargetFPS(60)
  if fullscreen { HideCursor() }
  render_size = {f32(GetRenderWidth()), f32(GetRenderHeight())}
}

initColor :: proc(color_mode: ColorModes) { using rl
  switch color_mode {
  case .SAME:
    start_color, end_color := getRandomColor(), getRandomColor()
    for &dc in depth_color { dc.start, dc.end = start_color, end_color }
  case .MIXED:
    for &dc in depth_color { dc.start, dc.end = getRandomColor(), getRandomColor() }
  case .GRAD:
    dc_start, dc_end, nc_start, nc_end := getRandomColor(), getRandomColor(), getRandomColor(), getRandomColor()
    for &dc, i in depth_color {
      dc.color = ColorLerp(dc_start, dc_start, f32(i) * .111111) //start color gradient
      dc.start = dc.color
      dc.end = ColorLerp(nc_start, nc_end, f32(i) * .111111) //next color gradient
    }
  }
}

initTriangleHeight :: proc() { if triangle_height == 0 {triangle_height = render_size.y - 81 }}

// h = ( s * sqrt(3) ) / 2 || s = ( 2 * h ) / sqrt(3) -- 2 from top and bottom
initTriangle :: proc() { using rl
  max_height := render_size.y - 81
  if triangle_height > render_size.y - 81 { triangle_height = max_height }
  if triangle_height < 81 { triangle_height = 81 }
  triangle = {
    {(render_size.x / 2), (render_size.y - triangle_height) / 2}, //v1
    {(render_size.x / 2) - ((triangle_height) / math.sqrt(f32(3))), triangle_height + ((render_size.y - triangle_height) / 2)}, //v2
    {(render_size.x / 2) + ((triangle_height) / math.sqrt(f32(3))), triangle_height + ((render_size.y - triangle_height) / 2)}  //v3
  }
}

getKeyPresses :: proc() { using rl
  key := GetKeyPressed()
  for key > .KEY_NULL {
    #partial switch key {
    case .T: rotate, bounce = false, false; initTriangleHeight(); initTriangle() //re-init triangle
    case .R: if IsKeyDown(.LEFT_CONTROL) { rotate_angle *= -1 } else { rotate = !rotate } //toggle rotation
    case .P: pause_color = !pause_color //pause color lerping
    case .D: draw_solid = !draw_solid //toggle solid triangles
    case .V: inverted = !inverted //toggle solid triangles
    case .M: color_mode = ColorModes((i32(color_mode) + 1) % len(ColorModes)); initColor(color_mode) //cycle color modes
    case .C: controls = !controls //toggle controls display
    case .I: info = !info //toggle info display
    case .B: bounce = !bounce //toggle bounce
    case .ZERO..=.NINE: max_depth = i32(key) - 48 //set triangle depth
    case .UP:
      modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
      if !modifier_keys { color_speed = color_speed+0.02 > 1 ? 1:color_speed+0.02 } //increase color lerp speed
      if IsKeyDown(.LEFT_SHIFT) { bounce_speed = bounce_speed+0.05 > 10 ? 10:bounce_speed+0.05 } //increase bounce speed
      if IsKeyDown(.LEFT_ALT) && IsKeyDown(.UP) {resizeTriangle(1.02) } //increase triangle size
      if IsKeyDown(.LEFT_CONTROL) { rotate_angle += 0.05 ; if rotate_angle > 6 { rotate_angle = 6} } //increase rotation angle
    case .DOWN:
      modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
      if !modifier_keys { color_speed = color_speed-0.02 < 0 ? 0:color_speed-0.02 } //decrease color lerp speed
      if IsKeyDown(.LEFT_SHIFT) { bounce_speed = bounce_speed-0.05 < 0 ? 0:bounce_speed-0.05 } //decrease bounce speed
      if IsKeyDown(.LEFT_ALT) && IsKeyDown(.DOWN) { resizeTriangle(0.98) } //decrease triangle size
      if IsKeyDown(.LEFT_CONTROL) { rotate_angle -= 0.05; if rotate_angle < -6 { rotate_angle = -6} } //decrease rotation angle
    }
    key = GetKeyPressed()
  }
}

getRandomColor :: proc() -> rl.Color { using rl
  return { u8(GetRandomValue(0,255)), u8(GetRandomValue(0,255)), u8(GetRandomValue(0,255)), 255 }
}

lerpColor :: proc(color_mode: ColorModes) { using rl
  if !pause_color {
    lerp_time += GetFrameTime() * color_speed
    switch color_mode {
    case .SAME:
      if lerp_time > 1.0 { // Clamp time
        lerp_time = 0.0
        random_color := getRandomColor()
        for &dc in depth_color { dc.start = dc.end; dc.end = random_color }
      }
      for &dc in depth_color { dc.color = ColorLerp(dc.start, dc.end, lerp_time) }
    case .MIXED:
      if lerp_time > 1.0 { // Clamp time
        lerp_time = 0.0
        for &dc in depth_color { dc.start = dc.end; dc.end = getRandomColor() }
      }
      for &dc in depth_color { dc.color = ColorLerp(dc.start, dc.end, lerp_time) }
    case .GRAD:
      if lerp_time > 1.0 { // Clamp time
        lerp_time = 0.0
        start_color := getRandomColor()
        end_color   := getRandomColor()
        for &dc, i in depth_color {
          dc.start = dc.end
          dc.end = ColorLerp(start_color, end_color, f32(i) * .1111111)
        }
      }
      for &dc in depth_color { dc.color = ColorLerp(dc.start, dc.end, lerp_time) }
    }
  }
}

updateText :: proc() { using rl
  DT :: rl.DrawText; TF :: rl.TextFormat
  width := i32(render_size.x)
  info_format =     { {20, 20},          {285,20},          30 + 5, 30, 5, rl.GRAY }
  controls_format = { {width - 570, 20}, {width - 280, 20}, 30 + 5, 30, 5, rl.GRAY }
  nf := &info_format; cf := &controls_format

  if info { //info text
  rt_text: cstring = rotate != false ? TF("%f°", rotate_angle) : "OFF"
  bn_text: cstring = bounce ? TF("%f", bounce_speed)  : "OFF"
  cs_text: cstring = pause_color ? "PAUSED" : TF("%f", color_speed)
  DT("ROTATE ANGLE:",  nf.v1.x, nf.v1.y + 0*nf.lh, nf.fs, nf.c); DT(TF("%s", rt_text),         nf.v2.x, nf.v2.y + 0*nf.lh, nf.fs, nf.c)
  DT("BOUNCE SPEED:",  nf.v1.x, nf.v1.y + 1*nf.lh, nf.fs, nf.c); DT(TF("%s", bn_text),         nf.v2.x, nf.v2.y + 1*nf.lh, nf.fs, nf.c)
  DT("COLOR SPEED:",   nf.v1.x, nf.v1.y + 2*nf.lh, nf.fs, nf.c); DT(TF("%s", cs_text),         nf.v2.x, nf.v2.y + 2*nf.lh, nf.fs, nf.c)
  DT("TRIANGLE SIZE:", nf.v1.x, nf.v1.y + 3*nf.lh, nf.fs, nf.c); DT(TF("%g", triangle_height), nf.v2.x, nf.v2.y + 3*nf.lh, nf.fs, nf.c)
  DT("DEPTH:",         nf.v1.x, nf.v1.y + 4*nf.lh, nf.fs, nf.c); DT(TF("%i", max_depth),       nf.v2.x, nf.v2.y + 4*nf.lh, nf.fs, nf.c)
  DT("FPS:",           nf.v1.x, nf.v1.y + 5*nf.lh, nf.fs, nf.c); DT(TF("%i", GetFPS()),        nf.v2.x, nf.v2.y + 5*nf.lh, nf.fs, nf.c)
  for dc, i in depth_color {
    if i32(i) <= max_depth { //color info text per depth to max_depth
      DT(TF("RGB %i",          i),       nf.v1.x, nf.v1.y + (i32(i)+6)*nf.lh, nf.fs, nf.c)
      DT(TF("%03i",   dc.color.r), 140 + nf.v1.x, nf.v2.y + (i32(i)+6)*nf.lh, nf.fs, nf.c)
      DT(TF("%03i",   dc.color.g), 210 + nf.v1.x, nf.v2.y + (i32(i)+6)*nf.lh, nf.fs, nf.c)
      DT(TF("%03i",   dc.color.b), 280 + nf.v1.x, nf.v2.y + (i32(i)+6)*nf.lh, nf.fs, nf.c)
    }
  }
  }
  if controls { //controls text
  P: cstring = pause_color ? "True" : "False"
  D: cstring = draw_solid  ? "True" : "False"
  V: cstring = inverted    ? "True" : "False"
  B: cstring = bounce      ? "True" : "False"
  R: cstring = rotate      ? "True" : "False"
  M: cstring = color_mode_names[color_mode]
  DT("Bounce Speed",      cf.v1.x, cf.v1.y + 0 *cf.lh, cf.fs, GRAY); DT("SHIFT+UP/DOWN", cf.v2.x, cf.v2.y + 0 *cf.lh, cf.fs, cf.c)
  DT("Rotate Angle +/-",  cf.v1.x, cf.v1.y + 1 *cf.lh, cf.fs, GRAY); DT("CTRL+UP/DOWN",  cf.v2.x, cf.v2.y + 1 *cf.lh, cf.fs, cf.c)
  DT("Rotate Angle Flip", cf.v1.x, cf.v1.y + 2 *cf.lh, cf.fs, GRAY); DT("CTRL+R",        cf.v2.x, cf.v2.y + 2 *cf.lh, cf.fs, cf.c)
  DT("Triangle Size",     cf.v1.x, cf.v1.y + 3 *cf.lh, cf.fs, GRAY); DT("ALT+UP/DOWN",   cf.v2.x, cf.v2.y + 3 *cf.lh, cf.fs, cf.c)
  DT("Color Speed",       cf.v1.x, cf.v1.y + 4 *cf.lh, cf.fs, GRAY); DT("UP/DOWN",       cf.v2.x, cf.v2.y + 4 *cf.lh, cf.fs, cf.c)
  DT("Sierpinksi Depth",  cf.v1.x, cf.v1.y + 5 *cf.lh, cf.fs, GRAY); DT("0-9",           cf.v2.x, cf.v2.y + 5 *cf.lh, cf.fs, cf.c)
  DT("Toggle Controls",   cf.v1.x, cf.v1.y + 6 *cf.lh, cf.fs, GRAY); DT("C",             cf.v2.x, cf.v2.y + 6 *cf.lh, cf.fs, cf.c)
  DT("Toggle Info",       cf.v1.x, cf.v1.y + 7 *cf.lh, cf.fs, GRAY); DT("I",             cf.v2.x, cf.v2.y + 7 *cf.lh, cf.fs, cf.c)
  DT("Reset Triangle",    cf.v1.x, cf.v1.y + 8 *cf.lh, cf.fs, GRAY); DT("T",             cf.v2.x, cf.v2.y + 8 *cf.lh, cf.fs, cf.c)
  DT("Toggle Rotate",     cf.v1.x, cf.v1.y + 9 *cf.lh, cf.fs, GRAY); DT("R",             cf.v2.x, cf.v2.y + 9 *cf.lh, cf.fs, cf.c); DT(R, cf.v2.x + 165, cf.v2.y + 9 *cf.lh, cf.fs, cf.c)
  DT("Pause Color",       cf.v1.x, cf.v1.y + 10*cf.lh, cf.fs, GRAY); DT("P",             cf.v2.x, cf.v2.y + 10*cf.lh, cf.fs, cf.c); DT(P, cf.v2.x + 165, cf.v2.y + 10*cf.lh, cf.fs, cf.c)
  DT("Toggle Bounce",     cf.v1.x, cf.v1.y + 11*cf.lh, cf.fs, GRAY); DT("B",             cf.v2.x, cf.v2.y + 11*cf.lh, cf.fs, cf.c); DT(B, cf.v2.x + 165, cf.v2.y + 11*cf.lh, cf.fs, cf.c)
  DT("Toggle Solid",      cf.v1.x, cf.v1.y + 12*cf.lh, cf.fs, GRAY); DT("D",             cf.v2.x, cf.v2.y + 12*cf.lh, cf.fs, cf.c); DT(D, cf.v2.x + 165, cf.v2.y + 12*cf.lh, cf.fs, cf.c)
  DT("Toggle Inverted",   cf.v1.x, cf.v1.y + 13*cf.lh, cf.fs, GRAY); DT("V",             cf.v2.x, cf.v2.y + 13*cf.lh, cf.fs, cf.c); DT(V, cf.v2.x + 165, cf.v2.y + 13*cf.lh, cf.fs, cf.c)
  DT("Color Mode",        cf.v1.x, cf.v1.y + 14*cf.lh, cf.fs, GRAY); DT("M",             cf.v2.x, cf.v2.y + 14*cf.lh, cf.fs, cf.c); DT(M, cf.v2.x + 165, cf.v2.y + 14*cf.lh, cf.fs, cf.c)
  }
}

sierpinsky :: proc(t: TriangleVector2, depth: i32) -> (fallout: bool) { using rl
  color: = depth_color[depth].color
  if inverted {
    if depth > 0 { //draw from 1 to max_depth
      if draw_solid { DrawTriangle((t.v1 + t.v2) / 2, (t.v2 + t.v3) / 2, (t.v1 + t.v3) / 2, color) }
      else { DrawTriangleLines((t.v1 + t.v2) / 2, (t.v2 + t.v3) / 2, (t.v1 + t.v3) / 2, color) }
    }
    else { //special case - draw depth 0 as not inverted with lines so outer edge has a border
      DrawTriangleLines(t.v1, t.v2, t.v3, depth_color[max_depth].color)
      if max_depth > 0 { sierpinsky(t, 1) }
      return true //fallout from special case
    }
  }
  else { //not inverted - draw from 0 to max_depth
    if draw_solid && depth == max_depth { DrawTriangle(t.v1, t.v2, t.v3, color) }
    else { DrawTriangleLines(t.v1, t.v2, t.v3, color) }
  }
  if depth + 1 <= max_depth { //recurse to max_depth
    sierpinsky({t.v1, (t.v1 + t.v2) / 2, (t.v1 + t.v3) / 2}, depth + 1) //top
    sierpinsky({(t.v1 + t.v2) / 2, t.v2, (t.v2 + t.v3) / 2}, depth + 1) //left
    sierpinsky({(t.v1 + t.v3) / 2, (t.v2 + t.v3) / 2, t.v3}, depth + 1) //right
  }
  return true //dumby return
}

rotateTriangle :: proc() { using rl
  if rotate { //centroid is center of mass, not half of height
    centroid := (triangle.v1 + triangle.v2 + triangle.v3) / 3
    triangle = {
      Vector2Rotate(triangle.v1 - centroid, rotate_angle * DEG2RAD) + centroid, //v1
      Vector2Rotate(triangle.v2 - centroid, rotate_angle * DEG2RAD) + centroid, //v2
      Vector2Rotate(triangle.v3 - centroid, rotate_angle * DEG2RAD) + centroid  //v3
    }
  }
}

bounceTriangle :: proc() { using rl
  if bounce { //using a lazy bounce, since 2 vectors can be offscreen simultaniously
    t, w, h := &triangle, render_size.x, render_size.y - 4
    if t.v1.x <= 0 || t.v2.x <= 0 || t.v3.x <= 0 { bounce_left_right = .RIGHT; if rotate { rotate_angle *= -1 } }
    if t.v1.x >= w || t.v2.x >= w || t.v3.x >= w { bounce_left_right = .LEFT;  if rotate { rotate_angle *= -1 } }
    if t.v1.y <= 0 || t.v2.y <= 0 || t.v3.y <= 0 { bounce_up_down    = .DOWN;  if rotate { rotate_angle *= -1 } }
    if t.v1.y >= h || t.v2.y >= h || t.v3.y >= h { bounce_up_down    = .UP;    if rotate { rotate_angle *= -1 } }
    #partial switch bounce_left_right {
      case .LEFT:  t.v1.x -= bounce_speed; t.v2.x -= bounce_speed; t.v3.x -= bounce_speed
      case .RIGHT: t.v1.x += bounce_speed; t.v2.x += bounce_speed; t.v3.x += bounce_speed
    }
    #partial switch bounce_up_down {
      case .UP:    t.v1.y -= bounce_speed; t.v2.y -= bounce_speed; t.v3.y -= bounce_speed
      case .DOWN:  t.v1.y += bounce_speed; t.v2.y += bounce_speed; t.v3.y += bounce_speed
    }
  }
}

resizeTriangle :: proc(factor: f32) { using math
  resized: TriangleVector2
  centroid := (triangle.v1 + triangle.v2 + triangle.v3) / 3
  resized.v1 = centroid + (triangle.v1 - centroid) * factor
  resized.v2 = centroid + (triangle.v2 - centroid) * factor
  resized.v3 = centroid + (triangle.v3 - centroid) * factor
  side := sqrt(pow((resized.v2.x - resized.v1.x), 2) + pow((resized.v2.y - resized.v1.y), 2))
  resized_height := floor((side * sqrt(f32(3))) / 2)
  if resized_height >= 81.0 && resized_height <= (render_size.y - 81.0) { 
    triangle = resized
    triangle_height = resized_height
  }
}