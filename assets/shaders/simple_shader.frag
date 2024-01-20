#include<flutter/runtime_effect.glsl>

uniform vec2 uResolution; // The resolution of the screen

uniform sampler2D uTexture; // The texture

out vec4 fragColor;

void main() {
    vec2 st=FlutterFragCoord().xy  / uResolution;

    fragColor = texture(uTexture, st);
}
