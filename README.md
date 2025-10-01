# Sierpinksi-2D-Triangle
Sierpinsky triangle drawn in 2D using Odin and Raylib. Command line options are availible for use as a screensaver. The compiled exe in this repository is for Windows only. The code should compile and run fine on Linux. Tested on Kubuntu.

# Notes:
- Press ESC to exit.
- Compute time is ~ O(3^MAXDEPTH).
- FPS target is set to 60.
- Use <-h> command line option for help
- Press L or C to see keyboard control options.
- Three color modes are availible.

# Command LIne Options:
- -triangle size, -s, size in height of triangle range: float = 81.0 : screen height - 81.0
- -maxdepth, -d, sierpinski depth range: int = 0 : 9
- -colorspeed, -c, color change speed, range: float = 0.0 : 1.0
- -rotateangle, -a, enables rotation and sets speed/direction, range: float = -6.0 : 6.0
- -bouncespeed", -b, enables bounce and sets speed, range: float = 0.0 : 10.0
- -colormode, -m, sets color mode, default = same - values: same, mixed, or grad
- -legend, -l, enables/disables display of controls legend, default = true
- -ui, -u, enables/disables display of main ui, default = true
- -wireframe, -w, enables/disables wireframe, default = false
- -inverted, -i, enables/disables drawing inverted, default = false

# Example Usage:
sierpinski.exe -s 600 -b true -a -0.3 -b 4 -w false -i false -m mixed -d 5 -l false -u false -f true
