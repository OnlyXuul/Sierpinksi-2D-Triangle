package sierpinski

import "core:fmt"
import rl "vendor:raylib"

//some color constants with alpha
GUILOGOGRAYALPHA :rl.Color: rl.Color{ 175, 175, 175, 255 }
GRAYALPHA        :rl.Color: {rl.GRAY.r, rl.GRAY.g, rl.GRAY.b, 200}
LIGHTGRAYALPHA   :rl.Color: {rl.LIGHTGRAY.r, rl.LIGHTGRAY.g, rl.LIGHTGRAY.b, 200}
DARKGRAYALPHA    :rl.Color: {rl.DARKGRAY.r,  rl.DARKGRAY.g,  rl.DARKGRAY.b,  200}
BLACKALPHA       :rl.Color: {rl.BLACK.r,     rl.BLACK.g,     rl.BLACK.b,     200}
BLUEALPHA        :rl.Color: {rl.BLUE.r,      rl.BLUE.g,      rl.BLUE.b,      200}
REDALPHA         :rl.Color: {rl.RED.r,       rl.RED.g,       rl.RED.b,       200}
RAYWHITEALPHA    :rl.Color: {rl.RAYWHITE.r,  rl.RAYWHITE.g,  rl.RAYWHITE.b,  200}
MAROONALPHA      :rl.Color: {rl.MAROON.r,    rl.MAROON.g,    rl.MAROON.b,    200}

//gui structure - contains all guis since this is a simple demo (could be made more generic)
GEntity :: struct {
  mwb:         RectVectUnion,
  cwb:         RectVectUnion,
  awb:         RectVectUnion,
  zproc:       [3]ZPROC,
  mwb_grid:    [22]MGrid,
  cwb_grid:    [16]CGrid,
  logos:       Logos,
  tt_style:    ToolTipStyle,
  mwb_tooltip: [MWBToolTipMap]ToolTip,
  cwb_tooltip: [CWBToolTipMAP]ToolTip,
  awb_tooltip: [AWBToolTipMAP]ToolTip,
  states:      bit_set[GStates],
}

//to allow swizzle of xy with v and still have a true Rectangle type with width, height
RectVectUnion :: struct #raw_union {
  using _: rl.Rectangle,
  v: rl.Vector4,
}

//simple zorder - no cascading only top - proc pointers for array use - fifo
//t is passed only so the main gui has axcess to t's data for configuration
ZPROC :: #type proc(g: ^GEntity, t: ^TEntity)

//x, y, labelwidth, datax, datawidth, ctrlx, ctrlwidth, height
MGrid :: struct {x,y,lw,dx,dw,cx,cw,h: f32}

//x,y,labelwidth, keyx, keywidth, height
CGrid :: struct {x,y,lw,kx,kw,h: f32}

//custom logos for about window
Logos :: struct {
  ol_logo: Logo,
  rl_logo: Logo,
  gl_logo: Logo,
  xl_logo: Logo,
}

//style for tooltips
ToolTipStyle :: struct {
  text_size:        f32,
  padding:          f32,
  text_spacing:     f32,
  border_width:     f32,
  font:             rl.Font,
  text_color:       rl.Color,
  border_color:     rl.Color,
  background_color: rl.Color,
}

//custom tooltip implimentation since raylib functionality is "meant for quick testing purposes"
ToolTip :: struct {
  text:   cstring,
  active: bool,
  style:  ToolTipStyle,
  loc:    rl.Rectangle,
  offset: rl.Vector2,
  anchor: enum {
  TOPLEFT,    TOPCENTER,    TOPRIGHT,
  CENTERLEFT, CENTER,       CENTERRIGHT,
  BOTTOMLEFT, BOTTOMCENTER, BOTTOMRIGHT 
  },
}

//main ui tooltips
MWBToolTipMap :: enum {
  MWBCLOSE,
  TOGGLECTRLS,
  TOGGLEABOUT,
  MAXDEPTH,
  COLORSPEED,
  BOUNCESPEED,
  ROTATEANGLE,
  TRIANGLESIZE,
  COLORMODE,
  RESERVED,
}

//controls/legend window tooltip
CWBToolTipMAP :: enum {
  CWBCLOSE,
}

//about window tooltip
AWBToolTipMAP :: enum {
  AWBCLOSE,
}

//gui states
GStates :: enum {
  MWBCLOSE,
  CWBCLOSE,
  AWBCLOSE,
  MWBMOVE,
  CWBMOVE,
  AWBMOVE,
  CMDROPDOWNACTIVE,
}

//create initial gui struct with relevant defaults
createGuis :: proc() -> (g: GEntity) { using rl
  g.mwb.v = {20, 20, 455, 600}
  updateMGrid(&g)
  g.cwb.v = {g.mwb.x + g.mwb.width + 10, g.mwb.y, 484, 480}
  updateCGrid(&g)
  g.states += {.AWBCLOSE} //about window is closed by default
  g.logos = {
    ol_logo = {{}, "ODIN",   {}, 30, BLUEALPHA,        RAYWHITEALPHA, {}, ol_glyph, {}},
    rl_logo = {{}, "raylib", {}, 30, RAYWHITEALPHA,    BLACKALPHA,    {}, rl_glyph, {}},
    gl_logo = {{}, "raygui", {}, 30, GUILOGOGRAYALPHA, DARKGRAYALPHA, {}, gl_glyph, {}},
    xl_logo = {{}, "xuul",   {}, 30, MAROONALPHA,      BLACKALPHA,    {}, xl_glyph, {}},
  }

  tt_style: ToolTipStyle = {24, 10, 4, 2, rl.GetFontDefault(), {}, {}, {}}
  g.zproc = {drawAWB, drawCWB, drawMWB}
  g.tt_style = {24, 10, 4, 2, rl.GetFontDefault(), {}, {}, {}}
  g.mwb_tooltip = { //empty loc and offset, it is set later
    .MWBCLOSE     = {"close main ui", false, tt_style, {}, {}, .TOPRIGHT},
    .TOGGLECTRLS  = {"toggle legend", false, tt_style, {}, {}, .TOPRIGHT},
    .TOGGLEABOUT  = {"About", false, tt_style, {}, {}, .TOPRIGHT},
    .MAXDEPTH     = {"range 0 : 9", false, tt_style, {}, {}, .CENTERLEFT},
    .COLORSPEED   = {"range 0.0 : 1.0", false, tt_style, {}, {}, .CENTERLEFT},
    .BOUNCESPEED  = {"range 0.0 : 10.0", false, tt_style, {}, {}, .CENTERLEFT},
    .ROTATEANGLE  = {"range 0.0 : 6.0", false, tt_style, {}, {}, .CENTERLEFT},
    .TRIANGLESIZE = {"range 81 : (screenheight - 81)", false, tt_style, {}, {}, .CENTERLEFT},
    .COLORMODE    = {"same  - fade on 1 color\n"+
                    "mixed - fade on distinct colors per depth\n"+
                    "grad  - fade between 2 colors", false, tt_style, {}, {}, .CENTERLEFT},
    .RESERVED     = {active = false},
  }

  g.cwb_tooltip = { //empty loc and offset, it is set later
    .CWBCLOSE = {"close legend", false, tt_style, {}, {}, .TOPRIGHT},
  }

  g.awb_tooltip = { //empty loc and offset, it is set later
    .AWBCLOSE = {"close about", false, tt_style, {}, {}, .TOPRIGHT},
  }
  
  return
}

//update grid map for main window elements - used by mouse controls when moving window
updateMGrid :: proc(g: ^GEntity) {
  for &mg, i in g.mwb_grid {
    mg.x = g.mwb.v.x
    mg.y = g.mwb.v.y + 32 + (28 * f32(i))
    mg.lw = 230
    mg.dx = g.mwb.v.x + 184
    mg.dw = 100
    mg.cx = g.mwb.v.x + 292
    mg.cw = 150
    mg.h = 20
  }
}

//update grid map for controls/legend window elements - used by mouse controls when moving window
updateCGrid :: proc(g: ^GEntity) {
  for &cg, i in g.cwb_grid {
    cg.x = g.cwb.v.x
    cg.y = g.cwb.v.y + 32 + (28 * f32(i))
    cg.lw = 240
    cg.kx = g.cwb.v.x + 240
    cg.kw = 240
    cg.h = 20
  }
}

//set a gui element to top of z-order - last in list is on top
zOrderTop :: proc(g: ^GEntity, p: ZPROC) {
  idx: int
  if g.zproc[len(g.zproc)-1] != p {
    for _, i in g.zproc { if g.zproc[i] == p { idx = i} } // find idx of proc
    for i in idx..<len(g.zproc)-1 { g.zproc[i] = g.zproc[i+1] } //shift procs left from idx loc
    g.zproc[len(g.zproc)-1] = p // add p to end
  } 
}

//draw guis by z-order - last in list is on top
drawZOrder :: proc(g: ^GEntity, t: ^TEntity) { for p in g.zproc { p(g, t) } }

//about window
drawAWB :ZPROC: proc(g: ^GEntity, _: ^TEntity) { using rl
  if .AWBCLOSE not_in g.states {
    mpos := GetMousePosition()
    if g.awb.v.xy == {0,0} { //initial location, afterwards let mouse control move window
      center_screen := [2]f32{f32(GetRenderWidth()), f32(GetRenderHeight())}
      g.awb.v = {(center_screen.x / 2) - (616 / 2), center_screen.y / 2 - (530 / 2), 616, 530}
    }

    is_top_z := g.zproc[len(g.zproc)-1] == drawAWB ? true:false
    if is_top_z { //draw a highlighted behind GuiWindowBox title if top
      DrawRectangleRec({g.awb.x, g.awb.y, g.awb.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.awb, "About")) && is_top_z { g.states += {.AWBCLOSE} }

    g.logos.ol_logo.xys = {g.awb.x + 28,  g.awb.y + g.awb.height - 156, 128}
    g.logos.rl_logo.xys = {g.awb.x + 172, g.awb.y + g.awb.height - 156, 128}
    g.logos.gl_logo.xys = {g.awb.x + 316, g.awb.y + g.awb.height - 156, 128}
    g.logos.xl_logo.xys = {g.awb.x + 460, g.awb.y + g.awb.height - 156, 128}

    g.awb_tooltip[.AWBCLOSE].loc = {g.awb.x + g.awb.width - 21, g.awb.y + 3, 17, 17}

    text1: cstring = "Yet another Sierpinski demo. This is my goto\n"+
                     "for learning a new graphics library. I love this\n"+
                     "fractal because of it's simplicity to implement\n"+
                     "while also demonstrating enough complexity to\n"+
                     "get a feel for the basics. Plus it's a good\n"+
                     "excuse to use recursion, which is not the most\n"+
                     "efficient approach vs iteration, but is fun to\n"+
                     "use and just feels so natural and right for\n"+
                     "fractals. If anyone ever sees this ...\n"+
                     "I hope you enjoyed.\n\n"+
                     "Find me at forum.odin-lang.org             --xuul"

    DrawTextEx(GetFontDefault(), "Sierpinski's Triangle", {g.awb.x + 20, g.awb.y + 34}, 50, 4, GRAYALPHA)
    DrawTextEx(GetFontDefault(), text1, {g.awb.x + 20, g.awb.y + 90}, 20, 4, GRAYALPHA)
    
    DrawRectangleLinesEx({g.awb.x + 20,  g.awb.y + g.awb.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.awb.x + 164, g.awb.y + g.awb.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.awb.x + 308, g.awb.y + g.awb.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.awb.x + 452, g.awb.y + g.awb.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    
    drawLogo(&g.logos.ol_logo, &g.logos.rl_logo, &g.logos.gl_logo, &g.logos.xl_logo)
    //stagger the start of each after the first
    staggerStatesMulti(&g.logos.ol_logo, &g.logos.rl_logo, &g.logos.gl_logo, &g.logos.xl_logo)

    for &tt in g.awb_tooltip { //draw tooltips last so they are ontop
      tt.active = isMouseExclusive(mpos, tt.loc) && is_top_z ? true:false
      drawToolTip(tt)
    }
  }
  else { ResetLogo(&g.logos.ol_logo, &g.logos.rl_logo, &g.logos.gl_logo, &g.logos.xl_logo) }
}

//controls/legend window
drawCWB :ZPROC: proc(g: ^GEntity, _: ^TEntity) { using rl
  if .CWBCLOSE not_in g.states {
    mpos := GetMousePosition()
    is_top_z := g.zproc[len(g.zproc)-1] == drawCWB ? true:false
    if is_top_z { //draw a highlighted behind GuiWindowBox title if top
      DrawRectangleRec({g.cwb.x, g.cwb.y, g.cwb.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.cwb, "Keyboard Controls Legend")) && is_top_z { g.states += {.CWBCLOSE} }
    controls_text: [16][2]cstring = {
      {"Quit", "ESC"},
      {"Bounce Speed", "SHIFT + UP/DOWN"}, {"Rotate Angle +/-", "CTRL + UP/DOWN"}, {"Triangle Size", "ALT + UP/DOWN"},
      {"Color Speed", "UP/DOWN"}, {"Rotate Flip", "CTRL + R"}, {"Sierpinksi Depth", "0 - 9"},
      {"Toggle Legend", "L"}, {"Toggle Main UI", "U"}, {"Reset Triangle", "T"},
      {"Toggle Rotate", "R"}, {"Pause Color", "P"}, {"Toggle Bounce", "B"},
      {"Toggle Wireframe", "W"}, {"Toggle Inverted", "I"}, {"Color Mode", "M"}
    }
    g.cwb_tooltip[.CWBCLOSE].loc = {g.cwb.x + g.cwb.width - 21, g.cwb.y + 3, 17, 17}
    for cg, i in g.cwb_grid { 
      GuiLabel({cg.x, cg.y, cg.lw, cg.h}, controls_text[i][0])
      GuiLabel({cg.kx, cg.y, cg.kw, cg.h}, controls_text[i][1])
    }
    for &tt in g.cwb_tooltip { //draw tooltips last so they are ontop
      tt.active = isMouseExclusive(mpos, tt.loc) && is_top_z ? true:false
      drawToolTip(tt)
    }
  }
}

//main ui window
drawMWB :ZPROC: proc(g: ^GEntity, t: ^TEntity) { using rl
  if .MWBCLOSE not_in g.states {
    mpos   := GetMousePosition()
    mwmove := GetMouseWheelMove()

    //used for on the fly rgb tooltips - found in last case for color picker panels
    rgb_tt: ToolTip
    rgb_tt.style = ttGetDefaultStyle()
    //rgb_tt.anchor = .CENTERLEFT

    is_top_z := g.zproc[len(g.zproc)-1] == drawMWB ? true:false
    if is_top_z { //draw a highlighted behind GuiWindowBox title if top
      DrawRectangleRec({g.mwb.x, g.mwb.y, g.mwb.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.mwb, fmt.ctprintf("Sierpinski 2D -- FPS: %i", GetFPS()))) && is_top_z { g.states += {.MWBCLOSE} }

    //title bar tooltips locations MWBCLOSE, TOGGLECTRLS and TOGGLEABOUT
    g.mwb_tooltip[.MWBCLOSE].loc    = {g.mwb.x + g.mwb.width - 21, g.mwb.y + 3, 17, 17}
    g.mwb_tooltip[.TOGGLECTRLS].loc = {g.mwb.x + g.mwb.width - 46, g.mwb.y + 3, 17, 17}
    g.mwb_tooltip[.TOGGLEABOUT].loc = {g.mwb.x + g.mwb.width - 71, g.mwb.y + 3, 17, 17}

    //activate titlebar tooltips
    g.mwb_tooltip[.MWBCLOSE].active    = isMouseExclusive(mpos, g.mwb_tooltip[.MWBCLOSE].loc)    && is_top_z ? true:false
    g.mwb_tooltip[.TOGGLECTRLS].active = isMouseExclusive(mpos, g.mwb_tooltip[.TOGGLECTRLS].loc) && is_top_z ? true:false
    g.mwb_tooltip[.TOGGLEABOUT].active = isMouseExclusive(mpos, g.mwb_tooltip[.TOGGLEABOUT].loc) && is_top_z ? true:false

    //title bar buttons CWB and AWB
    if GuiButton({g.mwb.x + g.mwb.width - 46, g.mwb.y + 3, 18, 18}, "") && is_top_z {
      g.states ~= {.CWBCLOSE}
      if is_top_z { g.cwb.v.xy = {g.mwb.x + g.mwb.width + 10, g.mwb.y} } //show controls next to mwb
      updateCGrid(g)
    }
    if isMouseExclusive(mpos, {g.mwb.x + g.mwb.width - 46, g.mwb.y + 3, 17, 17}) {
      GuiDrawIcon(.ICON_HELP, i32(g.mwb.x + g.mwb.width - 45), i32(g.mwb.y + 4), 1, BLACKALPHA)
    }
    else { GuiDrawIcon(.ICON_HELP, i32(g.mwb.x + g.mwb.width - 45), i32(g.mwb.y + 4), 1, DARKGRAYALPHA) }

    if GuiButton({g.mwb.x + g.mwb.width - 71, g.mwb.y + 3, 18, 18}, "") && is_top_z {
      g.states ~= {.AWBCLOSE}
    }
    if isMouseExclusive(mpos, {g.mwb.x + g.mwb.width - 71, g.mwb.y + 3, 17, 17}) {
      GuiDrawIcon(.ICON_INFO, i32(g.mwb.x + g.mwb.width - 70), i32(g.mwb.y + 4), 1, BLACKALPHA)
    }
    else { GuiDrawIcon(.ICON_INFO, i32(g.mwb.x + g.mwb.width - 70), i32(g.mwb.y + 4), 1, DARKGRAYALPHA) }

    #reverse for mg, i in g.mwb_grid { //draw resverse so dropdown is ontop of below controls
      tt: MWBToolTipMap
      label_rect := Rectangle{mg.x, mg.y, mg.lw, mg.h}
      data_rect  := Rectangle{mg.dx, mg.y, mg.dw, mg.h}
      ctrl_rect  := Rectangle{mg.cx, mg.y, mg.cw, mg.h}
      mw_active  := is_top_z && isMouseExclusive(mpos,ctrl_rect) && mwmove != 0 ? true:false
      dropdown_delay := .CMDROPDOWNACTIVE in g.states ? true:false //delay activation of controls drawn under dropdown

      switch i {
      case 0:
        tt = .MAXDEPTH
        depth := i32(t.depth)
        GuiLabel(label_rect, "Draw Depth:")
        GuiSpinner(ctrl_rect, "",&depth, 0, 9, false)
        if is_top_z { t.depth = u8(depth) }
        if mw_active { t.depth = u8(clamp(i32(t.depth) + i32(mwmove), 0, 9)) }
      case 1:
        tt = .COLORSPEED
        speed := t.color.speed
        GuiLabel(label_rect, "Color Speed:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.color.speed))
        GuiSlider(ctrl_rect, "", "", &speed, 0.0, 1.0)
        if is_top_z { t.color.speed = speed }
        if mw_active { t.color.speed = clamp(t.color.speed + (mwmove * 0.025), 0.0, 1.0) }
      case 2:
        tt = .BOUNCESPEED
        speed := t.move.speed
        GuiLabel(label_rect, "Bounce Speed:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.move.speed))
        GuiSlider(ctrl_rect, "", "", &speed, 0.0, 10.0)
        if is_top_z { t.move.speed = speed }
        if mw_active { t.move.speed = clamp(t.move.speed + (mwmove * 0.05), 0.0, 10.0) }
      case 3:
        tt = .ROTATEANGLE
        rotate_angle_abs := abs(t.move.a_o_r)
        GuiLabel(label_rect, "Rotate Angle:")
        GuiLabel(data_rect, fmt.ctprintf("%f°", rotate_angle_abs))
        GuiSlider(ctrl_rect, "", "", &rotate_angle_abs, 0.0, 6.0)
        if mw_active { rotate_angle_abs = clamp(rotate_angle_abs + (mwmove * 0.025), 0.0, 6.0) }
        if is_top_z { t.move.a_o_r = t.move.a_o_r < 0 ? rotate_angle_abs * -1 : rotate_angle_abs }
      case 4:
        tt = .TRIANGLESIZE
        triangle_size_slider := t.height
        GuiLabel(label_rect, "Triangle Size:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.height))
        GuiSlider(ctrl_rect, "", "", &triangle_size_slider, 81.0, t.screen.y - 81.0)
        if mw_active { triangle_size_slider = clamp(triangle_size_slider + (mwmove * 2), 81.0, t.screen.y - 81.0) }
        if is_top_z { resizeTriangle(t, triangle_size_slider / t.height) }
      case 5:
        tt = .COLORMODE
        old_color_mode := t.color.mode
        if !is_top_z { g.states -= {.CMDROPDOWNACTIVE} }
        cm_dropdown_active := .CMDROPDOWNACTIVE in g.states
        GuiLabel(label_rect, "Color Mode:")
        if GuiDropdownBox(ctrl_rect, t.color.options, &t.color.mode.i, cm_dropdown_active) {
          g.states ~= {.CMDROPDOWNACTIVE}
        }
        if mw_active { t.color.mode.i = clamp(t.color.mode.i + i32(mwmove), 0, 2) }
        if is_top_z { if old_color_mode != t.color.mode { initColor(t) } }
      case 6:
        tt = .RESERVED
        rotate := i32(.ROTATE in t.states)
        GuiLabel(label_rect, "Rotate Toggle:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &rotate)
        if is_top_z && !dropdown_delay { t.states = bool(rotate) ? t.states + {.ROTATE} : t.states - {.ROTATE} }
        if mw_active { t.states = bool(clamp(rotate + i32(mwmove), 0, 1)) ? t.states + {.ROTATE} : t.states - {.ROTATE} }
      case 7:
        tt = .RESERVED
        pause_color := i32(.PAUSECOLOR in t.states)
        GuiLabel(label_rect, "Pause Color:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &pause_color)
        if is_top_z && !dropdown_delay { t.states = bool(pause_color) ? t.states + {.PAUSECOLOR} : t.states - {.PAUSECOLOR} }
        if mw_active { t.states = bool(clamp(pause_color + i32(mwmove), 0, 1)) ? t.states + {.PAUSECOLOR} : t.states - {.PAUSECOLOR} }
      case 8:
        tt = .RESERVED
        bounce := i32(.BOUNCE in t.states)
        GuiLabel(label_rect, "Bounce Toggle:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &bounce)
        if is_top_z && !dropdown_delay { t.states = bool(bounce) ? t.states + {.BOUNCE} : t.states - {.BOUNCE} }
        if mw_active { t.states = bool(clamp(bounce + i32(mwmove), 0, 1)) ? t.states + {.BOUNCE} : t.states - {.BOUNCE} }
      case 9:
        tt = .RESERVED
        wire_frame := i32(.WIREFRAME in t.states)
        GuiLabel(label_rect, "Wire Frame:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &wire_frame)
        if is_top_z && !dropdown_delay { t.states = bool(wire_frame) ? t.states + {.WIREFRAME} : t.states - {.WIREFRAME} }
        if mw_active { t.states = bool(clamp(wire_frame + i32(mwmove), 0, 1)) ? t.states + {.WIREFRAME} : t.states - {.WIREFRAME} }
      case 10:
        tt = .RESERVED
        inverted := i32(.INVERTED in t.states)
        GuiLabel(label_rect, "Inverted:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &inverted)
        if is_top_z && !dropdown_delay { t.states = bool(inverted) ? t.states + {.INVERTED} : t.states - {.INVERTED} }
        if mw_active { t.states = bool(clamp(inverted + i32(mwmove), 0, 1)) ? t.states + {.INVERTED} : t.states - {.INVERTED} }
      case 11:
        tt = .RESERVED
        GuiLabel(label_rect, "Reset Triangle:")
        if GuiButton(ctrl_rect, "Reset") {
          if is_top_z && !dropdown_delay {
            t.states -= {.ROTATE, .BOUNCE, .WIREFRAME,.INVERTED}
            t.states += {.PAUSECOLOR}
            initTriangle(t) //re-init triangle
          }
        }
      case 12..=21:
        tt = .RESERVED
        color := t.color.depth[i - 12].current
        rgb_tt = { //create on the fly tooltip for rgb color panel
          text = fmt.ctprintf("R: %i\nG: %i\nB: %i", color.r, color.g, color.b),
          active = isMouseExclusive(mpos, {mg.cx, mg.y, mg.cw, mg.h}) && is_top_z && u8(i) - 12 <= t.depth ? true:false,
          loc = {mg.cx, mg.y, mg.cw, mg.h},
          offset = {g.mwb.x + g.mwb.width - mpos.x, 0},
          anchor = .CENTERLEFT,
        }
        if u8(i) - 12 == t.depth && g.mwb.height != mg.y + 28 - g.mwb.y { g.mwb.height = mg.y + 28 - g.mwb.y } //last active guy in the list updates window height
        if u8(i) - 12 <= t.depth { //color per depth to max_depth
          GuiLabel({mg.x, mg.y, 275, mg.h}, fmt.ctprintf("RGB %i: %s", i - 12, ctohex(t.color.depth[i - 12].current)))
          GuiColorPanel({mg.cx, mg.y, mg.cw, mg.h},"", &t.color.depth[i - 12].current)
        }
      }
      drawToolTip(rgb_tt) //draw on the fly rgb tooltips
      if tt != .RESERVED { //draw tooltips for each case last so they are ontop
        g.mwb_tooltip[tt].loc = ctrl_rect
        g.mwb_tooltip[tt].offset = {g.mwb.x + g.mwb.width - mpos.x, 0}
        g.mwb_tooltip[tt].active = isMouseExclusive(mpos, g.mwb_tooltip[tt].loc) && is_top_z ? true:false
        drawToolTip(g.mwb_tooltip[tt])
      }
    }
    //draw tooltips for title bar buttons last so their z-order is on top
    drawToolTip(g.mwb_tooltip[.MWBCLOSE])
    drawToolTip(g.mwb_tooltip[.TOGGLECTRLS])
    drawToolTip(g.mwb_tooltip[.TOGGLEABOUT])
  }
}

//draw tooltip if active - set and then called by each gui window as they need
drawToolTip :: proc(tt: ToolTip) { using rl
  if tt.active {
    s := ttGetDefaultStyle(tt.style) //check for missing style elements
    mpos := GetMousePosition()
    t := MeasureTextEx(s.font, tt.text, s.text_size, s.text_spacing) //supports newlines
    w := t.x + (2 * s.border_width) + (2 * s.padding)
    h := t.y + (2 * s.border_width) + (2 * s.padding)
    x, y: f32
    switch tt.anchor {
    case .TOPLEFT:      x = mpos.x         ; y = mpos.y
    case .TOPCENTER:    x = mpos.x - (w/2) ; y = mpos.y
    case .TOPRIGHT:     x = mpos.x - w     ; y = mpos.y
    case .CENTERLEFT:   x = mpos.x         ; y = mpos.y - (h/2)
    case .CENTER:       x = mpos.x - (w/2) ; y = mpos.y - (h/2)
    case .CENTERRIGHT:  x = mpos.x - w     ; y = mpos.y - (h/2)
    case .BOTTOMLEFT:   x = mpos.x         ; y = mpos.y - h
    case .BOTTOMCENTER: x = mpos.x - (w/2) ; y = mpos.y - h
    case .BOTTOMRIGHT:  x = mpos.x - w     ; y = mpos.y - h
    }
    x += tt.offset.x; y += tt.offset.y
    DrawRectangleV({x,y},{w,h}, s.background_color)
    DrawRectangleLinesEx({x,y,w,h}, s.border_width, s.border_color)
    DrawTextEx(s.font, tt.text, {x + s.border_width + s.padding, y + s.border_width + s.padding}, s.text_size, s.text_spacing, s.text_color)
  }
}

//get and fill with .DEFAULT style properties if empty
ttGetDefaultStyle :: proc (style: ToolTipStyle = {}) -> (s: ToolTipStyle) { using rl
  s = style
  if s.text_size == {} { s.text_size = f32(GuiGetStyle(.DEFAULT, i32(GuiDefaultProperty.TEXT_SIZE)))}
  if s.padding == {} { s.padding = f32(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.TEXT_PADDING)))}
  if s.text_spacing == {} { s.text_spacing = f32(GuiGetStyle(.DEFAULT, i32(GuiDefaultProperty.TEXT_SPACING)))}
  if s.border_width == {} { s.border_width = f32(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BORDER_WIDTH)))}
  if s.font == {} { s.font = GetFontDefault() }
  if s.border_color == {} { s.border_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BORDER_COLOR_NORMAL)))}
  if s.background_color == {} { s.background_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BASE_COLOR_NORMAL)))}
  if s.text_color == {} { s.text_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.TEXT_COLOR_NORMAL)))}
  return
}