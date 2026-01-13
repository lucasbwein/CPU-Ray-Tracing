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
    float reflectivity;
    // float shininess; // for specular
};
struct Light {
    float3 position;
    float3 color;
};

struct GPUCamera {
    float4 position;
    float4 front;
    float4 up;
    float4 right;
    float fov;
    float aspectRatio;
};

struct Hit {
    bool hit = false;
    float t = 0.0f; // used for how far along until hit
    float3 point; // where the light hit
    float3 normal;
    int matID = -1;
    float3 color;
    float reflectivity;
};
constant int NUM_SPHERES = 5;
constant int SAMPLES_PER = 4;

/* ===================================
TODO:

ADD:
- snell's law (Refraction/Transparency)
- Specular lighting 
- Implement other object (cubes, pyramids)
- Textures (Normal Map)
- Path Tracing (for Global Illumination)
- Denoising

Optimizations
- Look into BVH (Bounding Volume Hierarchy)
- Spatial Partitioning

Later On (More Advance):
- Anti-Alisasing
- Soft Shadows
- Depth of Field

=================================== */

Ray generateRay(uint2 gid, float2 offset, constant GPUCamera* cam, uint2 gridSize);
float3 traceRay(Ray ray, thread Sphere* spheres, Light light, float3 camPos);
bool intersectSphere(Ray ray, Sphere sphere, float tMin, float tMax, thread Hit& hit);

kernel void rayTrace(
    texture2d<float, access::write> output [[texture(0)]],
    constant GPUCamera* camera [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]],
    uint2 gridSize [[threads_per_grid]])
{
    // Define Sphere and Light
    Sphere spheres[NUM_SPHERES] = {
        {{6.0, 5.5, 0.0}, 0.1, {1.0, 1.0, 1.0}, 0.0}, // Small sphere above light
        // {{0.0, 0.0, -5.0}, 1.0, {0.7, 0.4, 0.7}, 0.2},       // Magenta Sphere
        {{0.0, 0.0, -5.0}, 1.0, {1.0, 0.0, 0.0}, 0.0},       // Magenta Sphere
        {{2.2, 0.0, -5.0}, 1.0, {0.0, 1.0, 0.0}, 0.8},       // Green Sphere
         {{4.5, 0.0, -5.0}, 1.0, {0.9, 0.9, 0.9}, 0.95},   // Silver
        {{0.0, -101.5, -5.0}, 100.0, {0.5, 0.5, 0.5}, 0.3}   // Ground (gray)
    };
    Light light = {{5.0, 5.0, 0.0}, {1.0, 1.0, 1.0}};

    // Same typical logic for CPU ray tracing
    // but runs per pixel parallel, more efficient

    // gid.x = x && gid.y = y

    float2 offsets[4] = { // can generalize this by making it based of size and step
        {-0.25, -0.25},  // Top-left
        {0.25, -0.25},  // Top-right  
        {-0.25, 0.25},  // Bottom-left
        {0.25, 0.25}    // Bottom-right
    };

    float3 finalColor = float3(0.0);
    for (int sample = 0; sample < SAMPLES_PER; sample++) { // Generates basic Anti-Alisasing
        Ray ray = generateRay(gid, offsets[sample], camera, gridSize);
        float3 color = traceRay(ray, spheres, light, camera->position.xyz);

        finalColor += color;
    }

    finalColor /= float(SAMPLES_PER);
    // float3 color = ray.direction * 0.5 + 0.5;
    // float3 color = float3(camera->fov, camera->fov, camera->fov);

    output.write(float4(finalColor, 1.0), gid);
}

Ray generateRay(uint2 gid, float2 offset, constant GPUCamera* cam, uint2 gridSize) {
    Ray genRay;
    // Normalized pixel coordinates to [-1, 1]
    float u = 2.0 * (float(gid.x) + 0.5  + offset.x) / float(gridSize.x) - 1;
    float v = 2.0 * (float(gid.y) + 0.5 + offset.y) / float(gridSize.y) - 1;

    // Calculate scale FOV
    float scale = tan(cam->fov * 0.5f);

    // Calculate offset
    float3 dir_cam = cam->front.xyz 
                    + (u * cam->aspectRatio * scale) * cam->right.xyz
                    + (v * scale) * cam->up.xyz;

    // Generate ray
    genRay.origin = cam->position.xyz;
    genRay.direction = normalize(dir_cam);
    return genRay;
}

float3 traceRay(Ray primaryRay, thread Sphere* spheres, Light light, float3 camPos) {
    float3 finalColor = float3(0.0);
    float3 throughPut = float3(1.0);
    Ray currentRay = primaryRay;

    int maxBounces = 4;

    for(int bounce=0; bounce < maxBounces; bounce++){
        Hit hit;
        float tMin = 0.001f; // Removes too close
        float tMax = 9999.9f;
            
        // Calculates intersect
        for (int i=0; i < NUM_SPHERES; i++){
            if(intersectSphere(currentRay, spheres[i], tMin, tMax, hit)) {
                tMax = hit.t;
            }
        }

        // if ray hits calculates shadow and returns color
        if(hit.hit) {
            float3 lightDir = normalize(light.position - hit.point);
            float diffuse = max(dot(hit.normal, lightDir), 0.0f);

            float3 viewDir = normalize(camPos - hit.point);
            float3 reflectDir = reflect(-lightDir, hit.normal);
            float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

            // float ior = 1.5; // (Index of refraction)
            // float3 refracted = refract(currentRay.direction, hit.normal, 1.0 / ior);

            // Shadow Test
            Ray shadowRay;
            shadowRay.direction = lightDir;
            shadowRay.origin = hit.point;
            float dist_to_light = distance(hit.point, light.position);
            
            Hit shadowHit;
            for(int i=0; i < NUM_SPHERES; i++) {
                // if(sphere.matID == hit.matID) continue;
                if(intersectSphere(shadowRay, spheres[i], tMin, dist_to_light, shadowHit)){
                    diffuse *= 0.2;
                    break;
                }
            }
            
            float3 directLight = hit.color * diffuse * light.color + float3(1.0) * spec * 0.2;
            // float3 directLight = hit.color * diffuse * light.color;
            finalColor += throughPut * directLight;

            if (hit.reflectivity < 0.001) {
                break;
            }

            throughPut *= hit.color * hit.reflectivity;

            if (length(throughPut) < 0.001) {
                break;
            }

            // Create Reflected Ray
            currentRay.origin = hit.point;
            currentRay.direction = reflect(currentRay.direction, hit.normal);
        } else {
            // Hit Sky and Stops
            float a = 0.5f * (normalize(currentRay.direction).y + 1.0f);
            float3 skyColor = (1.0f - a) * float3(1.0f) + a * float3(0.5f, 0.7f, 1.0f);
            finalColor += skyColor * throughPut;
            break; // stops bouncing
        }
    }
    return finalColor;
}

bool intersectSphere(Ray ray, Sphere sphere, float tMin, float tMax, thread Hit& hit) {
    // Goal return true and update all params of hit

    float3 oc = ray.origin - sphere.center;
    float3 dir = ray.direction;
    float radius = sphere.radius;

    float a = dot(dir, dir);
    float b = 2.0f * dot(oc, dir);
    float c = dot(oc, oc) - radius * radius;

    float discriminant = b * b - 4 * a * c;

    if(discriminant < 0) return false;

    float sqrtDiscrim = sqrt(discriminant);

    float t0 = (-b - sqrtDiscrim) / (2.0 * a);
    float t1 = (-b + sqrtDiscrim) / (2.0 * a);

    if(t0 > t1) {
        float temp = t0;
        t0 = t1;
        t1 = temp;
    }
    float t = t0;

    if (t < tMin || t > tMax) {
        t = t1;
        if (t < tMin || t > tMax) {
            return false;
        }
    }

    // update hit
    hit.t = t;
    hit.point = ray.origin + t * ray.direction;
    hit.normal = normalize(hit.point - sphere.center);
    if(dot(hit.normal, ray.direction) > 0)
        hit.normal = -hit.normal;
    // hit.matID = matID;
    hit.hit = true;
    hit.color = sphere.color;
    hit.reflectivity = sphere.reflectivity;
    
    return true;
}