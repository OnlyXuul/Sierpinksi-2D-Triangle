package sierpinski

import rl "vendor:raylib"

//user input (mouse and keyboard) - with some special cases for gui windows
getUserInput :: proc(t: ^SEntity, g: ^GEntity) { using rl
  //Mouse
  mpos := GetMousePosition()
  top_z := g.zproc[len(g.zproc)-1]

  //hide curser if all gui(s) are closed - show if they are enabled again by key press
  if .MWBCLOSE in g.states && .CWBCLOSE in g.states && .AWBCLOSE in g.states { HideCursor() } else { ShowCursor() }
  
  //set z-order if mouse moves inside a window but is not inside another (i.e. overlapped and mouse is in both)
  if isMouseInRect(mpos, g.mwb.r) && !isMouseInRect(mpos, g.cwb.r) && !isMouseInRect(mpos, g.awb.r) &&
    .AWBMOVE not_in g.states && .CWBMOVE not_in g.states { zOrderTop(g, drawMWB) } //z-order check and set
  if isMouseInRect(mpos, g.cwb.r) && !isMouseInRect(mpos, g.mwb.r) && !isMouseInRect(mpos, g.awb.r) &&
    .AWBMOVE not_in g.states && .MWBMOVE not_in g.states { zOrderTop(g, drawCWB) } //z-order check and set
  if isMouseInRect(mpos, g.awb.r) && !isMouseInRect(mpos, g.mwb.r) && !isMouseInRect(mpos, g.cwb.r) &&
   .CWBMOVE not_in g.states && .MWBMOVE not_in g.states{ zOrderTop(g, drawAWB) } //z-order check and set

   //move windows under some sane conditions
  if IsMouseButtonPressed(.LEFT) { //check mouse for move
    if isMouseInRect(mpos, {g.mwb.r.x, g.mwb.r.y + 2, g.mwb.r.width, 24}) &&
      !isMouseInRect(mpos, g.mwb_tooltip[.MWBCLOSE].loc) &&
      !isMouseInRect(mpos, g.mwb_tooltip[.TOGGLECTRLS].loc) &&
      !isMouseInRect(mpos, g.mwb_tooltip[.TOGGLEABOUT].loc) &&
      top_z == drawMWB { g.states += {.MWBMOVE} }
    if isMouseInRect(mpos, {g.cwb.r.x, g.cwb.r.y + 2, g.cwb.r.width, 24}) &&
      !isMouseInRect(mpos, g.cwb_tooltip[.CWBCLOSE].loc) &&
      top_z == drawCWB { g.states += {.CWBMOVE} }
    if isMouseInRect(mpos, {g.awb.r.x, g.awb.r.y + 2, g.awb.r.width, 24}) &&
      !isMouseInRect(mpos, g.awb_tooltip[.AWBCLOSE].loc) &&
      top_z == drawAWB { g.states += {.AWBMOVE} }
  }

  if .MWBMOVE in g.states { g.mwb.v.xy += GetMouseDelta(); updateMGrid(g) } //move main window box
  if .CWBMOVE in g.states { g.cwb.v.xy += GetMouseDelta(); updateCGrid(g) } //move controls window box
  if .AWBMOVE in g.states { g.awb.v.xy += GetMouseDelta() } //move about window box
  if IsMouseButtonUp(.LEFT) { g.states -= {.MWBMOVE, .CWBMOVE, .AWBMOVE} } //disable move

  //Keyboard
  for key := GetKeyPressed(); key > .KEY_NULL; key = GetKeyPressed() {
    #partial switch key {
    case .T: t.states -= {.ROTATE, .BOUNCE, .WIREFRAME, .INVERTED}; t.states += {.PAUSECOLOR}; initTriangle(t) //reset triangle
    case .R: if IsKeyDown(.LEFT_CONTROL) { t.move.a_o_r *= -1 } else { t.states ~= {.ROTATE} } //toggle rotation
    case .P: t.states ~= {.PAUSECOLOR} //pause color lerping
    case .W: t.states ~= {.WIREFRAME} //toggle solid triangles
    case .I: t.states ~= {.INVERTED} //toggle inverted triangles
    case .M: t.color.mode.i = (t.color.mode.i + 1) % 3; initColor(t) //cycle color modes
    case .L, .C: g.states ~= {.CWBCLOSE} //toggle controls display - allow also C since I keep trying to use that one
    case .U: g.states ~= {.MWBCLOSE} //toggle main UI
    case .B: t.states ~= {.BOUNCE} //toggle bounce
    case .ZERO..=.NINE: t.depth = u8(key) - 48 //set triangle depth
    case .UP:
      modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
      if !modifier_keys { t.color.speed = t.color.speed + 0.02 > 1 ? 1 : t.color.speed + 0.02 } //increase color lerp speed
      if IsKeyDown(.LEFT_SHIFT) { t.move.speed = t.move.speed + 0.05 > 10 ? 10 : t.move.speed + 0.05 } //increase bounce speed
      if IsKeyDown(.LEFT_ALT) && IsKeyDown(.UP) {resizeTriangle(t, 1.02) } //increase triangle size
      if IsKeyDown(.LEFT_CONTROL) { //increase rotation angle
          rotate_angle_abs := abs(t.move.a_o_r)
          if t.move.a_o_r < 0 { t.move.a_o_r = (rotate_angle_abs + 0.05) * -1}
          else { t.move.a_o_r = rotate_angle_abs + 0.05 }
      }
    case .DOWN:
      modifier_keys := IsKeyDown(.LEFT_ALT) || IsKeyDown(.LEFT_CONTROL) || IsKeyDown(.LEFT_SHIFT)
      if !modifier_keys { t.color.speed = t.color.speed - 0.02 < 0 ? 0 : t.color.speed - 0.02 } //decrease color lerp speed
      if IsKeyDown(.LEFT_SHIFT) { t.move.speed = t.move.speed - 0.05 < 0 ? 0 : t.move.speed - 0.05 } //decrease bounce speed
      if IsKeyDown(.LEFT_ALT) && IsKeyDown(.DOWN) { resizeTriangle(t, 0.98) } //decrease triangle size
      if IsKeyDown(.LEFT_CONTROL) { //decrease rotation angle
        rotate_angle_abs := abs(t.move.a_o_r)
        if t.move.a_o_r < 0 { t.move.a_o_r = (rotate_angle_abs - 0.05) * -1}
        else { t.move.a_o_r = rotate_angle_abs - 0.05 }
      }
    }
  }
}