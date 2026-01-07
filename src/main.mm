#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import <Foundation/Foundation.h>

int main() {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    NSLog(@"Device %@", device.name);
    return 0;
}