package sierpinski

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

round :: math.round
sqrt  :: math.sqrt

//used for drawing a circle about a radius - the odin logo
cos_sin :: proc(a: f32) -> [2]f32 { return {math.cos(rl.DEG2RAD*a), math.sin(rl.DEG2RAD*a)} }

//random color shortcut
getRandomColor :: proc() -> rl.Color { using rl
  return { u8(GetRandomValue(0,255)), u8(GetRandomValue(0,255)), u8(GetRandomValue(0,255)), 255 }
}

//check if mouse is in an active location given by rect - ..any exclude_rects optional
isMouseExclusive :: proc(pos: [2]f32, include: rl.Rectangle, exclude: ..rl.Rectangle) -> (isexclusive: bool) {
  if len(exclude) > 0 { //check for exclusivity if ..any of not_rects are provided
    for ex in exclude {
      if pos.x >= ex.x &&
         pos.y >= ex.y &&
         pos.x <= ex.x + ex.width &&
         pos.y <= ex.y + ex.height {
         isexclusive = false
      }
    }
  }
  //if not false from above, return true if in active inclusive_rect
  if pos.x >= include.x &&
     pos.y >= include.y &&
     pos.x <= include.x + include.width &&
     pos.y <= include.y + include.height {
     isexclusive = true
  }
  return
}

//convert rl.Color to i32
ctoi32 :: proc(c: rl.Color) -> i32 { return i32(rl.ColorToInt(c)) }

//convert i32 color to rl.Color
i32toc :: proc(c: i32) -> (color: rl.Color) {
  color.r = u8((c >> 24) & 0xFF)
  color.g = u8((c >> 16) & 0xFF)
  color.b = u8((c >> 8) & 0xFF)
  color.a = u8(c & 0xFF)
  return
}

//convert rl.Color to hex string
ctohex :: proc(color: rl.Color) -> (hex: cstring) { using rl
  octet: cstring
  hex = fmt.ctprintf("%s", "0x")
  for c in color {
    octet = "" //reset for each loop
    if c == 0 { octet = fmt.ctprintf("%s", "00") }
    for i:=c; i > 0; i = i/16 {
      if i%16 > 9 { octet = fmt.ctprintf("%r%s", cast(rune)(i % 16 + 'A' - 10), octet) }
      else { octet = fmt.ctprintf("%r%s", cast(rune)(i % 16 + '0'), octet) }
    }
    if len(octet) < 2 { octet = fmt.ctprintf("%*s%s", 2-len(octet), "0", octet) }
    hex = fmt.ctprintf("%s%s", hex, octet)
  }
  return
}