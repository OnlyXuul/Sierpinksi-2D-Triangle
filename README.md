# Sierpinksi-2D-Triangle
Sierpinsky triangle drawn in 2D using Odin and Raylib. Command line options are availible for use as a screensaver. The compiled exe in this repository is for Windows only. The code should compile and run fine on Linux. Tested on Kubuntu.

# Notes:
- Press ESC to exit.
- Compute time is ~ O(3^MAXDEPTH).
- FPS target is set to 60.
- Use <-f true> command line option to use as screensaver. Cursor is only hidden in this mode.
- Press C to see keyboard control options.
- Color mode "same" is best for the non-inverted option. The other color modes are not apparent when drawn non-inverted. This is a side effect of the standard method to draw each triangle upright per depth. This results in all the lines getting redrawn on top of each other all the way to max depth.
- Inverted mode draws each depth by only drawing each triangle upside down.
- Three color modes are availible. All 3 mostly benefit from drawsolid option set to true and inverted set to true.

# Command LIne Options:
- -triangle size, -ts, size in height of triangle range: float = 81.0 : screen height - 81.0
- -maxdepth, -md, sierpinski depth range: int = 0 : 9
- -colorspeed, -cs, color change speed, range: float = 0.0 : 1.0
- -rotateangle, -ra, enables rotation and sets speed/direction, range: float = -6.0 : 6.0
- -bouncespeed", -bs, enables bounce and sets speed, range: float = 0.0 : 10.0
- -colormode, -cm, sets color mode, default = same - values: same, mixed, or grad
- -controls, -c, enables/disables display of controls info, default = true
- -info, -i, enables/disables display of info stats, default = true
- -drawsolid, -ds, enables/disables drawing solid, default = true
- -inverted, -iv, enables/disables drawing inverted, default = true
- -fullscreen, -f, enables/disables fullscreen (hides cursor), default = false

# Example Usage:
sierpinski.exe -ts 600 -b true -ra -0.3 -bs 4 -ds true -iv true -cm mixed -md 6 -c false -i false -f true
