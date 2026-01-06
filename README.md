# Overview
Simplistic implementation of ray tracing on the CPU. Works by computing the given lighting on objects which is then passed as a texture into the OpenGL pipeline allowing the render to be displayed.

![Ray Trace Demo](Demo_ScreenShot/Sphere_render.png)

## Future Plans
Plan to move to Metal to use a compute shader for calculating ray tracing. 

Note: Currently due to optimization runs at 3 FPS on modern computer.