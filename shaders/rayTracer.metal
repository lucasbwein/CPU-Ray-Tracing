// Metal Shading Language
#include <metal_stdlib>
using namespace metal;

// ray trace logic here
struct Ray {
    float3 origin;
    float3 direction;
};

struct Sphere {
    float3 center;
    float radius;
    float3 color;
};
struct Light {
    float3 position;
    float3 color;
};
struct GPUCamera {
    float3 position;
    float3 front;
    float3 up;
    float3 right;
    float fov;
    float aspectRatio;
};

kernel void rayTrace(
    texture2d<float, access::write> output [[texture(0)]],
    constant GPUCamera* camera [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]],
    uint2 gridSize [[threads_per_grid]])
{
    // Define Sphere and Light
    Sphere sphere[2] = {
        {{0.0, 0.0, -5.0}, 1.0, {1.0, 0.0, 0.0}},
        {{2.0, 0.0, -5.0}, 1.0, {0.0, 1.0, 0.0}}
    };
    Light light = {{5.0, 5.0, 0.0}, {1.0, 1.0, 1.0}};

    // Same typical logic for CPU ray tracing
    // but runs per pixel parallel, more efficient
    GPUCamera cam = *camera;
    
    // gid.x = x && gid.y = y

    //Ray ray = generateRay();
    //generateRay(gid.x, gid.y);
    
    //float3 color = traceRay(ray);

    float r = float(gid.x) / float(gridSize.x);
    float g = float(gid.y) / float(gridSize.y);

    //output.write(float4(color, 1.0), gid);
    output.write(float4(r, g, 0.0, 1.0), gid);
}