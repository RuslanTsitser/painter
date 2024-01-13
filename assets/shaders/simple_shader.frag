#include<flutter/runtime_effect.glsl>

uniform vec4 uColor; // The color to apply
uniform vec2 uResolution; // The resolution of the screen
uniform float angle; // The angle of rotation in radians

uniform sampler2D uTexture; // The texture

out vec4 fragColor;


vec2 rotateUV(vec2 uv, float rotation, float mid)
{
    return vec2(
      cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
      cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

void main() {
    vec2 st=FlutterFragCoord().xy  / uResolution;

    // Rotate the texture coordinates around 
    st = rotateUV(st, angle, 0.5);

    st = fract(st);

    // Get the color of the texture
    vec4 texColor = texture(uTexture, st);



    float delta = 0.9;
    // Check if the texture color is not transparent enough
    if (texColor.a > (1-delta)) {
        // If it is, use the color
        fragColor = uColor;
    } else {
        // If not, use transparent
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
