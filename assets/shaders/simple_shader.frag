#include<flutter/runtime_effect.glsl>

uniform vec2 uResolution; // The resolution of the screen

uniform sampler2D uTexture; // The texture

out vec4 fragColor;

// A function to perform simple anti-aliasing
vec4 applyAntiAliasing(vec2 coord) {
    vec2 aaLevel = vec2(1.0) / uResolution; // Adjust as needed, ensuring it's a vec2
    vec4 color = vec4(0.0);

    // Sample the texture at multiple points around the pixel and average them
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 sampleCoord = coord + vec2(float(x), float(y)) * aaLevel;
            color += texture(uTexture, sampleCoord);
        }
    }

    return color / 9.0; // Average of the 9 samples
}

void main() {
    vec2 st=FlutterFragCoord().xy  / uResolution;

    fragColor = applyAntiAliasing(st);
}
