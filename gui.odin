package sierpinski

import "core:fmt"
import rl "vendor:raylib"

///////////////////////////////////////////////////////////////////////////////////////////////
// Color constants with alpha
///////////////////////////////////////////////////////////////////////////////////////////////
GUILOGOGRAYALPHA :rl.Color: rl.Color{ 175, 175, 175, 255 }
GRAYALPHA        :rl.Color: {rl.GRAY.r, rl.GRAY.g, rl.GRAY.b, 200}
LIGHTGRAYALPHA   :rl.Color: {rl.LIGHTGRAY.r, rl.LIGHTGRAY.g, rl.LIGHTGRAY.b, 200}
DARKGRAYALPHA    :rl.Color: {rl.DARKGRAY.r,  rl.DARKGRAY.g,  rl.DARKGRAY.b,  200}
BLACKALPHA       :rl.Color: {rl.BLACK.r,     rl.BLACK.g,     rl.BLACK.b,     200}
BLUEALPHA        :rl.Color: {rl.BLUE.r,      rl.BLUE.g,      rl.BLUE.b,      200}
REDALPHA         :rl.Color: {rl.RED.r,       rl.RED.g,       rl.RED.b,       200}
RAYWHITEALPHA    :rl.Color: {rl.RAYWHITE.r,  rl.RAYWHITE.g,  rl.RAYWHITE.b,  200}
MAROONALPHA      :rl.Color: {rl.MAROON.r,    rl.MAROON.g,    rl.MAROON.b,    200}

///////////////////////////////////////////////////////////////////////////////////////////////
// Gui_Entity - contains all gui data
///////////////////////////////////////////////////////////////////////////////////////////////

Gui_Entity :: struct {
  main:   Gui_Main,
  legend: Gui_Legend,
  about:  Gui_About,
  zorder: [3]Gui_Draw_Proc,
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Gui_Main - main gui window
///////////////////////////////////////////////////////////////////////////////////////////////

Gui_Main :: struct {
  using rect: rl.Rectangle,
  using _:    Gui_Main_Tooltips,
  grid:       [22]Gui_Main_Grid,
  flags:      bit_set[Gui_Main_Flags],
}

Gui_Main_Tooltips :: struct {
  tooltip:       [Gui_Main_Tooltip_Map]Tooltip,
  tooltip_style: Tooltip_Style,
}

// main ui tooltips
Gui_Main_Tooltip_Map :: enum u8 {
  TT_CLOSE,
  TT_TOGGLELEGEND,
  TT_TOGGLEABOUT,
  TT_MAXDEPTH,
  TT_COLORSPEED,
  TT_BOUNCESPEED,
  TT_ROTATEANGLE,
  TT_TRIANGLESIZE,
  TT_COLORMODE,
  TT_RESERVED,
}

// x, y, labelwidth, datax, datawidth, ctrlx, ctrlwidth, height
Gui_Main_Grid :: struct { x, y, lw, dx, dw, cx, cw, h: f32 }

Gui_Main_Flags :: enum u8 {
  CLOSE,
  MOVE,
  DROPDOWNACTIVE,
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Gui_Legend - legend gui window
///////////////////////////////////////////////////////////////////////////////////////////////

Gui_Legend :: struct {
  using rect: rl.Rectangle,
  using _:    Gui_Legend_Tooltips,
  grid:       [16]Gui_Legend_Grid,
  flags:      bit_set[Gui_Legend_Flags],
}

Gui_Legend_Tooltips :: struct {
  tooltip:       [Gui_Legend_Tooltip_Map]Tooltip,
  tooltip_style: Tooltip_Style,
}

Gui_Legend_Tooltip_Map :: enum u8 {
  TT_CLOSE,
}

// x, y, labelwidth, keyx, keywidth, height
Gui_Legend_Grid :: struct { x, y, lw, kx, kw, h: f32 }

Gui_Legend_Flags :: enum u8 {
  CLOSE,
  MOVE,
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Gui_About - about gui window with logos
///////////////////////////////////////////////////////////////////////////////////////////////

Gui_About :: struct {
  using rect: rl.Rectangle,
  using _:    Gui_AbouTriangle_Tooltips,
  logos:      Logos,
  flags:      bit_set[Gui_AbouTriangle_Flags],
}

Gui_AbouTriangle_Tooltips :: struct {
  tooltip:       [Gui_AbouTriangle_Tooltip_Map]Tooltip,
  tooltip_style: Tooltip_Style,
}

// about window tooltip
Gui_AbouTriangle_Tooltip_Map :: enum u8 {
  TT_CLOSE,
}

Gui_AbouTriangle_Flags :: enum u8 {
  CLOSE,
  MOVE,
}

// custom logos for about window
Logos :: struct {
  ol_logo: Logo,
  rl_logo: Logo,
  gl_logo: Logo,
  xl_logo: Logo,
}

///////////////////////////////////////////////////////////////////////////////////////////////
// Tooltip structures
///////////////////////////////////////////////////////////////////////////////////////////////

// custom tooltip implimentation since raylib functionality is "meant for quick testing purposes"
Tooltip :: struct {
  text:   cstring,
  active: bool,
  style:  Tooltip_Style,
  loc:    rl.Rectangle,
  offset: rl.Vector2,
  anchor: enum {
  TOPLEFT,    TOPCENTER,    TOPRIGHT,
  CENTERLEFT, CENTER,       CENTERRIGHT,
  BOTTOMLEFT, BOTTOMCENTER, BOTTOMRIGHT 
  },
}

// style for tooltips
Tooltip_Style :: struct {
  text_size:        f32,
  padding:          f32,
  text_spacing:     f32,
  border_width:     f32,
  font:             rl.Font,
  text_color:       rl.Color,
  border_color:     rl.Color,
  background_color: rl.Color,
}

///////////////////////////////////////////////////////////////////////////////
// Procedure pointer type
// Defines draw_gui_zorder for array in Gui_Entity
// Also used by set_gui_zorder_top
///////////////////////////////////////////////////////////////////////////////

Gui_Draw_Proc :: #type proc(g: ^Gui_Entity, t: ^Triangle_Entity)

///////////////////////////////////////////////////////////////////////////////
// Gui_Entity default constructor
///////////////////////////////////////////////////////////////////////////////

create_gui_entity :: proc() -> (g: Gui_Entity) { using rl
  g.main.rect = {20, 20, 455, 600}
  update_main_grid(&g)

  // Open legend gui next to main gui
  g.legend.rect = {g.main.rect.x + g.main.rect.width + 10, g.main.rect.y, 484, 480}
  update_legend_grid(&g)

  //start about gui in center
  center_screen := [2]f32{f32(GetRenderWidth()), f32(GetRenderHeight())}
  g.about.rect = {(center_screen.x / 2) - (616 / 2), center_screen.y / 2 - (530 / 2), 616, 530}
  g.about.flags += {.CLOSE} // about window is closed by default

  // Logos definitions
  g.about.logos = {
    ol_logo = {{}, "ODIN",   {}, 30, BLUEALPHA,        RAYWHITEALPHA, {}, ol_glyph, {}},
    rl_logo = {{}, "raylib", {}, 30, RAYWHITEALPHA,    BLACKALPHA,    {}, rl_glyph, {}},
    gl_logo = {{}, "raygui", {}, 30, GUILOGOGRAYALPHA, DARKGRAYALPHA, {}, gl_glyph, {}},
    xl_logo = {{}, "xuul",   {}, 30, MAROONALPHA,      BLACKALPHA,    {}, xl_glyph, {}},
  }

  // Set initial zorder with main ontop
  g.zorder = {draw_about, draw_legend, draw_main}

  // Main gui tooltips
  g.main.tooltip_style = {24, 10, 4, 2, rl.GetFontDefault(), {}, {}, {}}
  g.main.tooltip = { //empty loc and offset, it is set when gui draws
    .TT_CLOSE      = {"close main ui", false, g.main.tooltip_style, {}, {}, .TOPRIGHT},
    .TT_TOGGLELEGEND  = {"toggle legend", false, g.main.tooltip_style, {}, {}, .TOPRIGHT},
    .TT_TOGGLEABOUT   = {"About", false, g.main.tooltip_style, {}, {}, .TOPRIGHT},
    .TT_MAXDEPTH      = {"range 0 : 9", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_COLORSPEED    = {"range 0.0 : 1.0", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_BOUNCESPEED   = {"range 0.0 : 10.0", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_ROTATEANGLE   = {"range 0.0 : 6.0", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_TRIANGLESIZE  = {"range 81 : (screenheight - 81)", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_COLORMODE     = {"same  - fade on 1 color\n"+
                        "mixed - fade on distinct colors per depth\n"+
                        "grad  - fade between 2 colors", false, g.main.tooltip_style, {}, {}, .CENTERLEFT},
    .TT_RESERVED      = {active = false},
  }

  // Legend gui tooltips
  g.legend.tooltip_style = {24, 10, 4, 2, rl.GetFontDefault(), {}, {}, {}}
  g.legend.tooltip = { // empty loc and offset, it is set when gui draws
    .TT_CLOSE = {"close legend", false, g.legend.tooltip_style, {}, {}, .TOPRIGHT},
  }

  // About gui tooltips
  g.about.tooltip_style  = {24, 10, 4, 2, rl.GetFontDefault(), {}, {}, {}}
  g.about.tooltip = { // empty loc and offset, it is set when gui draws
    .TT_CLOSE = {"close about", false,  g.about.tooltip_style, {}, {}, .TOPRIGHT},
  }
  
  return
}

///////////////////////////////////////////////////////////////////////////////
// General Gui procedures
///////////////////////////////////////////////////////////////////////////////

// set a gui element to top of z-order - last in list is on top
set_gui_zorder_top :: proc(g: ^Gui_Entity, p: Gui_Draw_Proc) {
  idx: int
  if g.zorder[len(g.zorder)-1] != p {
    for _, i in g.zorder { // find idx of proc
      if g.zorder[i] == p { idx = i}
    }
    for i in idx..<len(g.zorder)-1 { // shift procs left from idx loc
      g.zorder[i] = g.zorder[i+1]
    }
    g.zorder[len(g.zorder)-1] = p // add p to end
  } 
}

set_gui_zorder_bottom :: proc(g: ^Gui_Entity, p: Gui_Draw_Proc) {
  idx: int
  if g.zorder[0] != p {
    for _, i in g.zorder { // find idx of proc
      if g.zorder[i] == p { idx = i}
    }
    for i := idx; i > 0; i -= 1 { // shift procs right from idx loc
      g.zorder[i] = g.zorder[i-1]
    }
    g.zorder[0] = p // add p to beginning
  }
}

// Draw guis by z-order - last in list is on top - no cascading
draw_gui_zorder :: proc(g: ^Gui_Entity, t: ^Triangle_Entity) {
  for procedure in g.zorder { procedure(g, t) }
}

///////////////////////////////////////////////////////////////////////////////
// Specific Gui procedures
///////////////////////////////////////////////////////////////////////////////

// Update grid map for main window elements - used by mouse controls when moving window
update_main_grid :: proc(g: ^Gui_Entity) {
  for &mg, i in g.main.grid {
    mg.x  = g.main.x
    mg.y  = g.main.y + 32 + (28 * f32(i))
    mg.lw = 230
    mg.dx = g.main.x + 184
    mg.dw = 100
    mg.cx = g.main.x + 292
    mg.cw = 150
    mg.h  = 20
  }
}

// Update grid map for legend window elements - used by mouse controls when moving window
update_legend_grid :: proc(g: ^Gui_Entity) {
  for &lg, i in g.legend.grid {
    lg.x  = g.legend.x
    lg.y  = g.legend.y + 32 + (28 * f32(i))
    lg.lw = 240
    lg.kx = g.legend.x + 240
    lg.kw = 240
    lg.h  = 20
  }
}

// Draw main gui window
draw_main :: proc(g: ^Gui_Entity, t: ^Triangle_Entity) { using rl
  if .CLOSE not_in g.main.flags {
    mpos   := GetMousePosition()
    mwmove := GetMouseWheelMove()

    //used for on the fly rgb tooltips - found in last case for color picker panels
    rgb_tt: Tooltip
    rgb_tt.style = get_tooltip_default_style()

    is_top_z := g.zorder[len(g.zorder)-1] == draw_main ? true:false
    if is_top_z { //draw a highlighted behind GuiWindowBox title if top
      DrawRectangleRec({g.main.x, g.main.y, g.main.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.main, fmt.ctprintf("Sierpinski 2D -- FPS: %i", GetFPS()))) && is_top_z {
      set_gui_zorder_bottom(g, draw_main)
      g.main.flags += {.CLOSE}
    }

    //title bar tooltips locations MWBCLOSE, TOGGLECTRLS and TOGGLEABOUT
    g.main.tooltip[.TT_CLOSE].loc    = {g.main.x + g.main.width - 21, g.main.y + 3, 17, 17}
    g.main.tooltip[.TT_TOGGLELEGEND].loc = {g.main.x + g.main.width - 46, g.main.y + 3, 17, 17}
    g.main.tooltip[.TT_TOGGLEABOUT].loc = {g.main.x + g.main.width - 71, g.main.y + 3, 17, 17}

    //activate titlebar tooltips
    g.main.tooltip[.TT_CLOSE].active    = is_mouse_exclusive(mpos, g.main.tooltip[.TT_CLOSE].loc)    && is_top_z ? true:false
    g.main.tooltip[.TT_TOGGLELEGEND].active = is_mouse_exclusive(mpos, g.main.tooltip[.TT_TOGGLELEGEND].loc) && is_top_z ? true:false
    g.main.tooltip[.TT_TOGGLEABOUT].active = is_mouse_exclusive(mpos, g.main.tooltip[.TT_TOGGLEABOUT].loc) && is_top_z ? true:false

    //title bar buttons CWB and AWB
    if GuiButton({g.main.x + g.main.width - 46, g.main.y + 3, 18, 18}, "") && is_top_z {
      g.legend.flags ~= {.CLOSE}
      if .CLOSE not_in g.legend.flags { set_gui_zorder_top(g, draw_legend) }
    }
    if is_mouse_exclusive(mpos, {g.main.x + g.main.width - 46, g.main.y + 3, 17, 17}) {
      GuiDrawIcon(.ICON_HELP, i32(g.main.x + g.main.width - 45), i32(g.main.y + 4), 1, BLACKALPHA)
    }
    else { GuiDrawIcon(.ICON_HELP, i32(g.main.x + g.main.width - 45), i32(g.main.y + 4), 1, DARKGRAYALPHA) }

    if GuiButton({g.main.x + g.main.width - 71, g.main.y + 3, 18, 18}, "") && is_top_z {
      center_screen := [2]f32{f32(GetRenderWidth()), f32(GetRenderHeight())}
      g.about.rect = {(center_screen.x / 2) - (616 / 2), center_screen.y / 2 - (530 / 2), 616, 530}
      g.about.flags ~= {.CLOSE}
      if .CLOSE not_in g.about.flags { set_gui_zorder_top(g, draw_about) }
    }
    if is_mouse_exclusive(mpos, {g.main.x + g.main.width - 71, g.main.y + 3, 17, 17}) {
      GuiDrawIcon(.ICON_INFO, i32(g.main.x + g.main.width - 70), i32(g.main.y + 4), 1, BLACKALPHA)
    }
    else { GuiDrawIcon(.ICON_INFO, i32(g.main.x + g.main.width - 70), i32(g.main.y + 4), 1, DARKGRAYALPHA) }

    #reverse for mg, i in g.main.grid { //draw resverse so dropdown is ontop of below controls
      tt: Gui_Main_Tooltip_Map
      label_rect     := Rectangle{mg.x, mg.y, mg.lw, mg.h}
      data_rect      := Rectangle{mg.dx, mg.y, mg.dw, mg.h}
      ctrl_rect      := Rectangle{mg.cx, mg.y, mg.cw, mg.h}
      mw_active      := is_top_z && is_mouse_exclusive(mpos,ctrl_rect) && mwmove != 0 ? true:false
      dropdown_delay := .DROPDOWNACTIVE in g.main.flags ? true:false //delay activation of controls drawn under dropdown

      switch i {
      case 0:
        tt = .TT_MAXDEPTH
        depth := i32(t.depth)
        GuiLabel(label_rect, "Draw Depth:")
        GuiSpinner(ctrl_rect, "",&depth, 0, 9, false)
        if is_top_z  { t.depth = u8(depth) }
        if mw_active { t.depth = u8(clamp(i32(t.depth) + i32(mwmove), 0, 9)) }
      case 1:
        tt = .TT_COLORSPEED
        speed := t.color_speed
        GuiLabel(label_rect, "Color Speed:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.color_speed))
        GuiSlider(ctrl_rect, "", "", &speed, 0.000, 1.000)
        if is_top_z  { t.color_speed = speed }
        if mw_active { t.color_speed = clamp(t.color_speed + (mwmove * 0.025), 0.000, 1.000) }
      case 2:
        tt = .TT_BOUNCESPEED
        speed := t.move_speed
        GuiLabel(label_rect, "Bounce Speed:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.move_speed))
        GuiSlider(ctrl_rect, "", "", &speed, 0.000, 10.000)
        if is_top_z  { t.move_speed = speed }
        if mw_active { t.move_speed = clamp(t.move_speed + (mwmove * 0.050), 0.000, 10.000) }
      case 3:
        tt = .TT_ROTATEANGLE
        rotate_angle_abs := abs(t.move_aor)
        GuiLabel(label_rect, "Rotate Angle:")
        GuiLabel(data_rect, fmt.ctprintf("%f°", rotate_angle_abs))
        GuiSlider(ctrl_rect, "", "", &rotate_angle_abs, 0.000, 6.000)
        if mw_active { rotate_angle_abs = clamp(rotate_angle_abs + (mwmove * 0.025), 0.000, 6.000) }
        if is_top_z  { t.move_aor = t.move_aor < 0 ? rotate_angle_abs * -1 : rotate_angle_abs }
      case 4:
        tt = .TT_TRIANGLESIZE
        triangle_size_slider := t.height
        GuiLabel(label_rect, "Triangle Size:")
        GuiLabel(data_rect, fmt.ctprintf("%f", t.height))
        GuiSlider(ctrl_rect, "", "", &triangle_size_slider, 81.000, f32(GetRenderHeight()) - 81.000)
        if mw_active { triangle_size_slider = clamp(triangle_size_slider + (mwmove * 2), 81.000, f32(GetRenderHeight()) - 81.000) }
        if is_top_z  { scale_triangle(t, triangle_size_slider / t.height) }
      case 5:
        tt = .TT_COLORMODE
        old_color_mode := t.color_mode
        color_mode_i32 := i32(t.color_mode)
        if !is_top_z { g.main.flags -= {.DROPDOWNACTIVE} }
        dropdown_active := .DROPDOWNACTIVE in g.main.flags
        GuiLabel(label_rect, "Color Mode:")
        if GuiDropdownBox(ctrl_rect, t.color_options, &color_mode_i32, dropdown_active) {
          g.main.flags ~= {.DROPDOWNACTIVE}
        }
        t.color_mode = Triangle_Color_Mode(color_mode_i32)
        if mw_active { t.color_mode = Triangle_Color_Mode(clamp(color_mode_i32 + i32(mwmove), 0, 2)) }
        if is_top_z && old_color_mode != t.color_mode { init_color(t) }
      case 6:
        tt = .TT_RESERVED
        rotate := i32(.ROTATE in t.flags)
        GuiLabel(label_rect, "Rotate Toggle:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &rotate)
        if is_top_z  && !dropdown_delay { t.flags = bool(rotate) ? t.flags + {.ROTATE} : t.flags - {.ROTATE} }
        if mw_active && !dropdown_delay { t.flags = bool(clamp(rotate + i32(mwmove), 0, 1)) ? t.flags + {.ROTATE} : t.flags - {.ROTATE} }
      case 7:
        tt = .TT_RESERVED
        pause_color := i32(.PAUSECOLOR in t.flags)
        GuiLabel(label_rect, "Pause Color:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &pause_color)
        if is_top_z  && !dropdown_delay { t.flags = bool(pause_color) ? t.flags + {.PAUSECOLOR} : t.flags - {.PAUSECOLOR} }
        if mw_active && !dropdown_delay { t.flags = bool(clamp(pause_color + i32(mwmove), 0, 1)) ? t.flags + {.PAUSECOLOR} : t.flags - {.PAUSECOLOR} }
      case 8:
        tt = .TT_RESERVED
        bounce := i32(.BOUNCE in t.flags)
        GuiLabel(label_rect, "Bounce Toggle:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &bounce)
        if is_top_z  && !dropdown_delay { t.flags = bool(bounce) ? t.flags + {.BOUNCE} : t.flags - {.BOUNCE} }
        if mw_active && !dropdown_delay { t.flags = bool(clamp(bounce + i32(mwmove), 0, 1)) ? t.flags + {.BOUNCE} : t.flags - {.BOUNCE} }
      case 9:
        tt = .TT_RESERVED
        wire_frame := i32(.WIREFRAME in t.flags)
        GuiLabel(label_rect, "Wire Frame:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &wire_frame)
        if is_top_z  && !dropdown_delay { t.flags = bool(wire_frame) ? t.flags + {.WIREFRAME} : t.flags - {.WIREFRAME} }
        if mw_active && !dropdown_delay { t.flags = bool(clamp(wire_frame + i32(mwmove), 0, 1)) ? t.flags + {.WIREFRAME} : t.flags - {.WIREFRAME} }
      case 10:
        tt = .TT_RESERVED
        inverted := i32(.INVERTED in t.flags)
        GuiLabel(label_rect, "Inverted:")
        GuiToggleSlider(ctrl_rect, "OFF;ON", &inverted)
        if is_top_z  && !dropdown_delay { t.flags = bool(inverted) ? t.flags + {.INVERTED} : t.flags - {.INVERTED} }
        if mw_active && !dropdown_delay { t.flags = bool(clamp(inverted + i32(mwmove), 0, 1)) ? t.flags + {.INVERTED} : t.flags - {.INVERTED} }
      case 11:
        tt = .TT_RESERVED
        GuiLabel(label_rect, "Reset Triangle:")
        if GuiButton(ctrl_rect, "Reset") {
          if is_top_z && !dropdown_delay {
            t.flags -= {.ROTATE, .BOUNCE, .WIREFRAME,.INVERTED}
            t.flags += {.PAUSECOLOR}
            init_triangle(t) //re-init triangle
          }
        }
      case 12..=21:
        tt = .TT_RESERVED
        color := t.color[i - 12].current
        rgb_tt = { //create on the fly tooltip for rgb color panel
          text = fmt.ctprintf("R: %i\nG: %i\nB: %i", color.r, color.g, color.b),
          active = is_mouse_exclusive(mpos, {mg.cx, mg.y, mg.cw, mg.h}) && is_top_z && u8(i) - 12 <= t.depth ? true:false,
          loc = {mg.cx, mg.y, mg.cw, mg.h},
          offset = {g.main.x + g.main.width - mpos.x, 0},
          anchor = .CENTERLEFT,
        }
        if u8(i) - 12 == t.depth && g.main.height != mg.y + 28 - g.main.y { g.main.height = mg.y + 28 - g.main.y } //last active guy in the list updates window height
        if u8(i) - 12 <= t.depth { //color per depth to max_depth
          GuiLabel({mg.x, mg.y, 275, mg.h}, fmt.ctprintf("RGB %i: %s", i - 12, ctohex(t.color[i - 12].current)))
          GuiColorPanel({mg.cx, mg.y, mg.cw, mg.h},"", &t.color[i - 12].current)
        }
      }
      draw_tooltip(rgb_tt) //draw on the fly rgb tooltips
      if tt != .TT_RESERVED { //draw tooltips for each case last so they are ontop
        g.main.tooltip[tt].loc = ctrl_rect
        g.main.tooltip[tt].offset = {g.main.x + g.main.width - mpos.x, 0}
        g.main.tooltip[tt].active = is_mouse_exclusive(mpos, g.main.tooltip[tt].loc) && is_top_z ? true:false
        draw_tooltip(g.main.tooltip[tt])
      }
    }
    //draw tooltips for title bar buttons last so their z-order is on top
    draw_tooltip(g.main.tooltip[.TT_CLOSE])
    draw_tooltip(g.main.tooltip[.TT_TOGGLELEGEND])
    draw_tooltip(g.main.tooltip[.TT_TOGGLEABOUT])
  }
}

// Draw legend gui
draw_legend :: proc(g: ^Gui_Entity, _: ^Triangle_Entity) { using rl
  if .CLOSE not_in g.legend.flags {
    mpos := GetMousePosition()
    is_top_z := g.zorder[len(g.zorder)-1] == draw_legend ? true:false
    if is_top_z { // draw a highlighted rec behind GuiWindowBox title if top
      DrawRectangleRec({g.legend.x, g.legend.y, g.legend.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.legend, "Keyboard Controls Legend")) && is_top_z {
      set_gui_zorder_bottom(g, draw_legend)
      g.legend.flags += {.CLOSE}
    }

    controls_text: [16][2]cstring = {
      {"Quit", "ESC"},
      {"Bounce Speed", "SHIFT + UP/DOWN"}, {"Rotate Angle +/-", "CTRL + UP/DOWN"}, {"Triangle Size", "ALT + UP/DOWN"},
      {"Color Speed", "UP/DOWN"}, {"Rotate Flip", "CTRL + R"}, {"Sierpinksi Depth", "0 - 9"},
      {"Toggle Legend", "L"}, {"Toggle Main UI", "U"}, {"Reset Triangle", "T"},
      {"Toggle Rotate", "R"}, {"Pause Color", "P"}, {"Toggle Bounce", "B"},
      {"Toggle Wireframe", "W"}, {"Toggle Inverted", "I"}, {"Color Mode", "M"}
    }

    for lg, i in g.legend.grid { 
      GuiLabel({lg.x, lg.y, lg.lw, lg.h}, controls_text[i][0])
      GuiLabel({lg.kx, lg.y, lg.kw, lg.h}, controls_text[i][1])
    }
    
    g.legend.tooltip[.TT_CLOSE].loc = {g.legend.x + g.legend.width - 21, g.legend.y + 3, 17, 17}
    for &tt in g.legend.tooltip { // draw tooltips last so they are ontop
      tt.active = is_mouse_exclusive(mpos, tt.loc) && is_top_z ? true:false
      draw_tooltip(tt)
    }
  }
}

// Draw about gui
draw_about :: proc(g: ^Gui_Entity, _: ^Triangle_Entity) { using rl
  if .CLOSE not_in g.about.flags {
    mpos := GetMousePosition()

    is_top_z := g.zorder[len(g.zorder)-1] == draw_about ? true:false
    if is_top_z { // draw a highlighted behind GuiWindowBox title if top
      DrawRectangleRec({g.about.x, g.about.y, g.about.width, 24}, GRAYALPHA)
    }
    if bool(GuiWindowBox(g.about, "About")) && is_top_z {
      set_gui_zorder_bottom(g, draw_about)
      g.about.flags += {.CLOSE}
    }

    g.about.logos.ol_logo.xys = {g.about.x + 28,  g.about.y + g.about.height - 156, 128}
    g.about.logos.rl_logo.xys = {g.about.x + 172, g.about.y + g.about.height - 156, 128}
    g.about.logos.gl_logo.xys = {g.about.x + 316, g.about.y + g.about.height - 156, 128}
    g.about.logos.xl_logo.xys = {g.about.x + 460, g.about.y + g.about.height - 156, 128}

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

    DrawTextEx(GetFontDefault(), "Sierpinski's Triangle", {g.about.x + 20, g.about.y + 34}, 50, 4, GRAYALPHA)
    DrawTextEx(GetFontDefault(), text1, {g.about.x + 20, g.about.y + 90}, 20, 4, GRAYALPHA)
    
    DrawRectangleLinesEx({g.about.x + 20,  g.about.y + g.about.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.about.x + 164, g.about.y + g.about.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.about.x + 308, g.about.y + g.about.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    DrawRectangleLinesEx({g.about.x + 452, g.about.y + g.about.height - 164, 144, 144}, 8, LIGHTGRAYALPHA)
    
    draw_logo(&g.about.logos.ol_logo, &g.about.logos.rl_logo, &g.about.logos.gl_logo, &g.about.logos.xl_logo)
    // Stagger the start of each after the first
    stagger_logo_state(&g.about.logos.ol_logo, &g.about.logos.rl_logo, &g.about.logos.gl_logo, &g.about.logos.xl_logo)

    g.about.tooltip[.TT_CLOSE].loc = {g.about.x + g.about.width - 21, g.about.y + 3, 17, 17}
    for &tt in g.about.tooltip { //draw tooltips last so they are ontop
      tt.active = is_mouse_exclusive(mpos, tt.loc) && is_top_z ? true:false
      draw_tooltip(tt)
    }
  }
  else { reset_logo(&g.about.logos.ol_logo, &g.about.logos.rl_logo, &g.about.logos.gl_logo, &g.about.logos.xl_logo) }
}

///////////////////////////////////////////////////////////////////////////////
// Tooltip procedures
///////////////////////////////////////////////////////////////////////////////

// Draw tooltip if active - set and then called by each gui window as they need
draw_tooltip :: proc(tt: Tooltip) { using rl
  if tt.active {
    x, y: f32
    style     := get_tooltip_default_style(tt.style) // check for missing style elements
    mouse_pos := GetMousePosition()
    text_size := MeasureTextEx(style.font, tt.text, style.text_size, style.text_spacing) // supports newlines
    width     := text_size.x + (2 * style.border_width) + (2 * style.padding)
    height    := text_size.y + (2 * style.border_width) + (2 * style.padding)
    
    switch tt.anchor {
    case .TOPLEFT:      x = mouse_pos.x             ; y = mouse_pos.y
    case .TOPCENTER:    x = mouse_pos.x - (width/2) ; y = mouse_pos.y
    case .TOPRIGHT:     x = mouse_pos.x - width     ; y = mouse_pos.y
    case .CENTERLEFT:   x = mouse_pos.x             ; y = mouse_pos.y - (height/2)
    case .CENTER:       x = mouse_pos.x - (width/2) ; y = mouse_pos.y - (height/2)
    case .CENTERRIGHT:  x = mouse_pos.x - width     ; y = mouse_pos.y - (height/2)
    case .BOTTOMLEFT:   x = mouse_pos.x             ; y = mouse_pos.y - height
    case .BOTTOMCENTER: x = mouse_pos.x - (width/2) ; y = mouse_pos.y - height
    case .BOTTOMRIGHT:  x = mouse_pos.x - width     ; y = mouse_pos.y - height
    }

    x += tt.offset.x
    y += tt.offset.y

    DrawRectangleV({x,y},{width,height}, style.background_color)
    DrawRectangleLinesEx({x,y,width,height}, style.border_width, style.border_color)
    tpos := Vector2{x + style.border_width + style.padding, y + style.border_width + style.padding}
    DrawTextEx(style.font, tt.text, tpos, style.text_size, style.text_spacing, style.text_color)
  }
}

// Get and fill with .DEFAULT style properties if empty
get_tooltip_default_style :: proc (style: Tooltip_Style = {}) -> (s: Tooltip_Style) { using rl
  s = style
  if s.text_size == {}        { s.text_size = f32(GuiGetStyle(.DEFAULT, i32(GuiDefaultProperty.TEXT_SIZE))) }
  if s.padding == {}          { s.padding = f32(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.TEXT_PADDING))) }
  if s.text_spacing == {}     { s.text_spacing = f32(GuiGetStyle(.DEFAULT, i32(GuiDefaultProperty.TEXT_SPACING))) }
  if s.border_width == {}     { s.border_width = f32(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BORDER_WIDTH))) }
  if s.font == {}             { s.font = GetFontDefault() }
  if s.border_color == {}     { s.border_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BORDER_COLOR_NORMAL))) }
  if s.background_color == {} { s.background_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.BASE_COLOR_NORMAL))) }
  if s.text_color == {}       { s.text_color = i32toc(GuiGetStyle(.DEFAULT, i32(GuiControlProperty.TEXT_COLOR_NORMAL))) }
  return
}