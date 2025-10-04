package sierpinski

import "core:math"
import rl "vendor:raylib"

Triangle :: [3]rl.Vector2

TEntity :: struct {
  v:      Triangle,
  depth:  u8,
  height: f32,
  color:  SColorData,
  move:   SMoveData,
  screen: [2]f32,
  states: bit_set[SStates],
}

SColorData :: struct {
  depth:     [10]SDepthColor,
  mode:      SColorModes,
  options:   cstring,
  speed:     f32,
  lerp_time: f32,
}

SDepthColor :: struct { start, end, current: rl.Color }

SColorModes :: struct #raw_union {
  e: enum { SAME, MIXED, GRAD },
  i: i32
}

SMoveData :: struct {
  a_o_r:     f32, //angle of rotation
  speed:     f32,
  direction: bit_set[SMoveDirections],
}

SMoveDirections :: enum { LEFT, RIGHT, UP, DOWN }

SStates :: enum {
  BOUNCE,
  ROTATE,
  WIREFRAME,
  INVERTED,
  PAUSECOLOR,
}

//create initial triangle with relevant defaults
createTriangle :: proc() -> (triangle: TEntity) {
  triangle.depth = 4
  triangle.height = 600
  triangle.color.mode.e = .GRAD
  triangle.color.speed = 0.20
  triangle.move.speed = 1.50
  triangle.move.direction += {.LEFT, .UP}
  triangle.move.a_o_r = 0.25
  return
}

//color mode control
lerpColor :: proc(t: ^TEntity) { using rl
  if .PAUSECOLOR not_in t.states {
    t.color.lerp_time += GetFrameTime() * t.color.speed
    switch t.color.mode.e {
    case .SAME:
      if t.color.lerp_time > 1.0 { // Clamp time
        t.color.lerp_time = 0.0
        random_color := getRandomColor()
        for &tcd in t.color.depth { tcd.start = tcd.end; tcd.end = random_color }
      }
      for &tcd in t.color.depth { tcd.current = ColorLerp(tcd.start, tcd.end, t.color.lerp_time) }
    case .MIXED:
      if t.color.lerp_time > 1.0 { // Clamp time
        t.color.lerp_time = 0.0
        for &tcd in t.color.depth { tcd.start = tcd.end; tcd.end = getRandomColor() }
      }
      for &tcd in t.color.depth { tcd.current = ColorLerp(tcd.start, tcd.end, t.color.lerp_time) }
    case .GRAD:
      if t.color.lerp_time > 1.0 { // Clamp time
        t.color.lerp_time = 0.0
        start_color := getRandomColor()
        end_color   := getRandomColor()
        for &tcd, i in t.color.depth {
          tcd.start = tcd.end
          tcd.end = ColorLerp(start_color, end_color, f32(i) * .1111111)
        }
      }
      for &tcd in t.color.depth { tcd.current = ColorLerp(tcd.start, tcd.end, t.color.lerp_time) }
    }
  }
}

//overload - choose inverted or standard
sierpinski :: proc(t: ^TEntity) { if .INVERTED in t.states { sierpinskiInverted(t, t.v, 0) } else { sierpinskiStandard(t, t.v, 0) } }

//inverted draws the inner (center) upside-down triangle at each depth, with a few special cases for flavor
sierpinskiInverted :: proc(t: ^TEntity, s: Triangle, curr_depth: u8) { using rl
  color: = t.color.depth[curr_depth].current

  //special cases without inverted vectors
  if t.depth == 0 && .WIREFRAME not_in t.states { DrawTriangle(s[0], s[1], s[2], t.color.depth[0].current) }
  if curr_depth == 0 { DrawTriangleLines(s[0], s[1], s[2], t.color.depth[0].current) }

  //invert vectors
  if .WIREFRAME in t.states && curr_depth > 0 { DrawTriangleLines((s[0] + s[1]) / 2, (s[1] + s[2]) / 2, (s[2] + s[0]) / 2, color) }
  if .WIREFRAME not_in t.states && curr_depth > 0 { DrawTriangle((s[0] + s[1]) / 2, (s[1] + s[2]) / 2, (s[2] + s[0]) / 2, color) }

  if curr_depth != 0 && curr_depth + 1 <= t.depth { //recurse to t.depth
    sierpinskiInverted(t, {s[0], (s[0] + s[1]) / 2, (s[0] + s[2]) / 2}, curr_depth + 1) //top   v0' = (v0+v0)/2, (v0+v1)/2, (v0+v2)/2
    sierpinskiInverted(t, {(s[1] + s[0]) / 2, s[1], (s[1] + s[2]) / 2}, curr_depth + 1) //left  v1' = (v1+v0)/2, (v1+v1)/2, (v1+v2)/2
    sierpinskiInverted(t, {(s[2] + s[0]) / 2, (s[2] + s[1]) / 2, s[2]}, curr_depth + 1) //right v3' = (v2+v0)/2, (v2+v1)/2, (v2+v2)/2
  }
  if curr_depth == 0 && t.depth > 0 { sierpinskiInverted(t, s, 1) }
}

//standard method - draw top, left, and right 3rds at each depth with some exceptions for flavor
sierpinskiStandard :: proc(t: ^TEntity, s: Triangle, curr_depth: u8) { using rl
  //not inverted - draw from 0 to t.depth
  color: = t.color.depth[curr_depth].current

  if .WIREFRAME in t.states { 
    sierpinskiInverted(t, s, 0)
  }

  if .WIREFRAME not_in t.states {
    #partial switch t.color.mode.e {
      case .SAME:
        if t.depth == 0 { DrawTriangle(s[0], s[1], s[2], color) }
        else if curr_depth % 2 == t.depth % 2 { DrawTriangle(s[0], s[1], s[2], BLACK); DrawTriangleLines(s[0], s[1], s[2], color) }
        else { DrawTriangle(s[0], s[1], s[2], color) }
      case:
        DrawTriangle(s[0], s[1], s[2], color)
    }
    if curr_depth + 1 <= t.depth { //recurse to t.depth
      sierpinskiStandard(t, {s[0], (s[0] + s[1]) / 2, (s[0] + s[2]) / 2}, curr_depth + 1) //top   v0' = (v0+v0)/2, (v0+v1)/2, (v0+v2)/2
      sierpinskiStandard(t, {(s[1] + s[0]) / 2, s[1], (s[1] + s[2]) / 2}, curr_depth + 1) //left  v1' = (v1+v0)/2, (v1+v1)/2, (v1+v2)/2
      sierpinskiStandard(t, {(s[2] + s[0]) / 2, (s[2] + s[1]) / 2, s[2]}, curr_depth + 1) //right v3' = (v2+v0)/2, (v2+v1)/2, (v2+v2)/2
    }
  }
}

//rotate about the centroid (center of mass, not half of height)
rotateTriangle :: proc(t: ^TEntity) { using rl
  if .ROTATE in t.states {
    centroid := (t.v[0] + t.v[1] + t.v[2]) / 3
    t.v = {
      Vector2Rotate(t.v[0] - centroid, t.move.a_o_r * DEG2RAD) + centroid, //v1
      Vector2Rotate(t.v[1] - centroid, t.move.a_o_r * DEG2RAD) + centroid, //v2
      Vector2Rotate(t.v[2] - centroid, t.move.a_o_r * DEG2RAD) + centroid  //v3
    }
  }
}

//using a lazy bounce, since 2 vectors can be offscreen simultaniously - no physics :(
bounceTriangle :: proc(t: ^TEntity) { using rl
  if .BOUNCE in t.states {
    s, w, h := t.move.speed, t.screen.x, t.screen.y - 4

    if t.v[0].x <= 0 || t.v[1].x <= 0 || t.v[2].x <= 0 {
      t.move.direction += {.RIGHT}; t.move.direction -= {.LEFT}
      if .ROTATE in t.states { t.move.a_o_r *= -1 }
    }
    if t.v[0].x >= w || t.v[1].x >= w || t.v[2].x >= w {
      t.move.direction += {.LEFT}; t.move.direction -= {.RIGHT}
      if .ROTATE in t.states { t.move.a_o_r *= -1 }
    }
    if t.v[0].y <= 0 || t.v[1].y <= 0 || t.v[2].y <= 0 {
      t.move.direction += {.DOWN}; t.move.direction -= {.UP}
      if .ROTATE in t.states { t.move.a_o_r *= -1 }
    }
    if t.v[0].y >= h || t.v[1].y >= h || t.v[2].y >= h {
      t.move.direction += {.UP}; t.move.direction -= {.DOWN}
      if .ROTATE in t.states { t.move.a_o_r *= -1 }
    }

    switch t.move.direction {
    case {.LEFT,  .UP}:   t.v[0] += {-s, -s}; t.v[1] += {-s, -s}; t.v[2] += {-s, -s}
    case {.LEFT,  .DOWN}: t.v[0] += {-s,  s}; t.v[1] += {-s,  s}; t.v[2] += {-s,  s}
    case {.RIGHT, .UP}:   t.v[0] += {s,  -s}; t.v[1] += {s,  -s}; t.v[2] += {s,  -s}
    case {.RIGHT, .DOWN}: t.v[0] += {s,   s}; t.v[1] += {s,   s}; t.v[2] += {s,   s}
    }
  }
}

//resize triangle based on factor of height
resizeTriangle :: proc(t: ^TEntity, factor: f32) { using math
  resized: Triangle
  centroid := (t.v[0] + t.v[1] + t.v[2]) / 3
  resized[0] = centroid + ((t.v[0] - centroid) * factor)
  resized[1] = centroid + ((t.v[1] - centroid) * factor)
  resized[2] = centroid + ((t.v[2] - centroid) * factor)
  side := sqrt(pow((resized[1].x - resized[0].x), 2) + pow((resized[1].y - resized[0].y), 2))
  resized_height := floor((side * sqrt(f32(3))) / 2)
  if resized_height >= 81.0 && resized_height <= (t.screen.y - 81.0) { 
    t.v = resized
    t.height = resized_height
  }
}