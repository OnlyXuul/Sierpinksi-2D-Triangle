package sierpinski

import rl "vendor:raylib"

LogoGlyph :: #type proc (l: Logo)

Logo :: struct {
  using xys: struct {x, y, s: f32 }, //square x, y, s (size) - logo.s/16 is used to scale width of animated lines
  text:     cstring,          //6 chars or less is best for default font
  font:     rl.Font,          //leave blank for default font
  fs:       f32,              //font size: for default font suggest 70 for s (size) 256, 30 for 128 etc.
  bg:       rl.Color,         //background color
  fg:       rl.Color,         //foreground color
  state:    u8,               //starts at 0 - set state to 0 before redrawing
  glyph:    LogoGlyph,        //glyph proc drawn at end - make relative to logo dimensions - leave as {} if not using
  c: struct { f, t, b: f32 }, //counters: frame, top(and left), bottom(and right), leave 0
}

//reset any number of logos
ResetLogo :: proc(logos: ..^Logo) { for logo in logos {logo.state = 0} }

//use for staggering multiple logs for a nice effect
staggerStates :: proc(lead: ^Logo, trail: ^Logo ) {
  if lead.state <= 2 { trail.state = 1} else if trail.state == 1 { trail.state = 2 }
}

//draw logo(s) - proc pointers used to save space on repeated copies of the same draw procedure in each case
drawLogo :: proc (logos: ..^Logo) { using rl
  for logo in logos {
    anime: [8]proc (logo: Logo) = {
      proc(logo: Logo) { DrawRectangleRec({logo.x, logo.y, logo.s, logo.s}, logo.bg) }, //background
      proc(logo: Logo) { DrawRectangleRec({logo.x, logo.y, logo.s/16, logo.s/16}, logo.fg) }, //small blinking box
      proc(logo: Logo) { DrawRectangleRec({logo.x, logo.y, logo.c.t, logo.s/16}, logo.fg) }, //top
      proc(logo: Logo) { DrawRectangleRec({logo.x, logo.y, logo.s/16, logo.c.t}, logo.fg) }, //left
      proc(logo: Logo) { DrawRectangleRec({logo.x + logo.s - (logo.s/16), logo.y, logo.s/16, logo.c.b}, logo.fg) }, //right
      proc(logo: Logo) { DrawRectangleRec({logo.x, logo.y + logo.s - (logo.s/16), logo.c.b , logo.s/16}, logo.fg) }, //bottom
      proc(logo: Logo) { DrawTextEx(logo.font, sub(logo), {logo.x, logo.y} + logo.s - txt(logo) - (2 * logo.s/16), logo.fs, 4, logo.fg) },
      proc(logo: Logo) { if logo.glyph != {} { logo.glyph(logo) } }
    }
    
    //font scaling for when font size is not set
    if logo.fs == 0 { logo.fs = round(logo.s/32*10-10) }

    //shortcuts used by DrawTextEx proc pointer above
    sub :: proc(logo: Logo) -> cstring { return TextSubtext(logo.text, 0, (i32(logo.c.f)/12) + 1) } // every 12 frames, one more letter
    txt :: proc(logo: Logo) -> rl.Vector2 { return MeasureTextEx(logo.font, logo.text, logo.fs, 4) }

    //state machine for logo animation
    switch logo.state {
    case 0:
      if logo.font == {} { logo.font = GetFontDefault() }
      logo.c = {0, 0, 0}
      logo.state = 1
    case 1: //small box blinking
      anime[0](logo^)
      if i32(logo.c.f) % 30 >= 15 { anime[1]((logo^)) } //blink square on/off every 15 frames
      logo.c.f +=1
      if logo.c.f >= 120 { logo.state = 2; logo.c.f = 0 } //reset frame counter for text case
    case 2: //top and left bars growing
      if logo.c.t == 0 { logo.c.t = logo.s/16 } //kickstart at 0 for smoother transition
      for i in 0..=3 { anime[i](logo^) }
      logo.c.t += logo.s/64
      if logo.c.t >= logo.s { logo.state = 3; logo.c.f = 0 } //reset frame counter incase state 1 was manually skipped
    case 3: //bottom and right bars growing
      if logo.c.b == 0 { logo.c.b = logo.s/16 } //kickstart at 0 for smoother transition
      for i in 0..=5 { anime[i](logo^) }
      logo.c.b += logo.s/64
      if logo.c.b >= logo.s { logo.state = 4; logo.c.f = 0 } //reset frame counter incase state 1 was manually skipped
    case 4: //letters appearing (one by one)
      for i in 0..=6 { anime[i](logo^) }
      logo.c.f += 1
      if i32(logo.c.f) >= (12 * i32(len(logo.text))) { logo.state = 5 }
    case 5: //everything
      for i in 0..=7 { anime[i](logo^) }
    }
  }
}

//custom odin logo
ol_glyph :LogoGlyph: proc(logo: Logo) { using rl
  vec:    [4]Vector2
  thick:  f32 = clamp(round(logo.s/64), 1, 4)
  radius: f32 = logo.s/8
  deg:    Vector4 = {140, 270, -70, 120}
  center: Vector2 = {logo.x, logo.y} + {logo.s, logo.s/64} + {-4, 4} * logo.s/16
  for &v, i in vec { v = radius * cos_sin(deg[i]) + center}
  segments: i32 = IsWindowState({.MSAA_4X_HINT}) ? 60 : 360 //draw fewer segnets if MSAA enabled - let it do the work
  DrawRing(center, radius - thick, radius, deg[0], deg[1], segments, WHITE)
  DrawRing(center, radius - thick, radius, deg[2], deg[3], segments, WHITE)
  DrawLineEx(vec[0], vec[1], thick, WHITE)
  DrawLineEx(vec[2], vec[3], thick, WHITE)
}

//custom raylib logo
rl_glyph :LogoGlyph: proc(logo: Logo) {
  rl.DrawTriangle(
    {logo.x, logo.y} + {logo.s, 0} + {-2, 2} * logo.s/16,
    {logo.x, logo.y} + {logo.s, 0} + {-6, 2} * logo.s/16,
    {logo.x, logo.y} + {logo.s, 0} + {-2, 6} * logo.s/16, rl.RED)
}

//custom raygui logo
gl_glyph :LogoGlyph: proc(logo: Logo) {
  psize:     f32 = clamp(round(logo.s/64), 1, 4)
  scale:     f32 = ((psize*16)/16)*16
  wspace: [2]f32 = {1,2}
  rl.GuiDrawIcon(
    .ICON_WINDOW,
    i32(logo.x + logo.s - (2 * logo.s/16) - scale + wspace.x),
    i32(logo.y + (2 * logo.s/16) - wspace.y),
    i32(psize), logo.fg)
}

//custom xuul logo
xl_glyph :LogoGlyph: proc(logo: Logo) {
  psize:     f32 = clamp(round(logo.s/64), 1, 4)
  scale:     f32 = ((psize*16)/16)*16
  wspace: [2]f32 = {2,1} 
  rl.GuiDrawIcon(
    .ICON_DEMON,
    i32(logo.x + logo.s - (2 * logo.s/16) - scale + wspace.x),
    i32(logo.y + (2 * logo.s/16) - wspace.y),
    i32(psize), logo.fg)
}