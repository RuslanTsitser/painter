#version 460 core

#include<flutter/runtime_effect.glsl>

uniform float u_shift_left;
uniform float u_shift_top;
uniform float u_angle;// Line angle in degrees
uniform vec4 u_color;// Color to tint texture
uniform vec2 u_resolution;// Screen resolution
uniform sampler2D u_texture;// Texture sampler

out vec4 FragColor;

void main(){
    // Normalize pixel coordinates (0.0 to 1.0)
    vec2 st=gl_FragCoord.xy/u_resolution;
    
    // Adjust for aspect ratio to ensure texture isn't stretched
    float aspectRatio=u_resolution.x/u_resolution.y;
    vec2 aspectCorrect=vec2(aspectRatio*st.x,st.y);
    
    // Scaling factor for repeating the texture
    float scale=.2;// Adjust this to increase/decrease the number of repeats
    
    // Apply rotation
    float angle=radians(u_angle);
    mat2 rotationMatrix=mat2(cos(angle),-sin(angle),sin(angle),cos(angle));
    vec2 centeredCoord=aspectCorrect-2;// Move origin to center for rotation
    vec2 rotatedCoord=rotationMatrix*centeredCoord+.5;// Apply rotation
    
    // Shift the texture to the left
    float shiftLeft=u_shift_left;// This value can be adjusted to move the texture further to the left
    float shiftTop=u_shift_top;// This value can be adjusted to move the texture further to the top
    vec2 shiftedCoord=vec2(rotatedCoord.x-shiftLeft,rotatedCoord.y+shiftTop);
    
    // Repeat the texture by scaling the texture coordinates
    vec2 repeatedCoord=shiftedCoord*scale;
    
    // Sample texture with rotated, repeated, and shifted coordinates and apply color
    vec4 texColor=texture(u_texture,repeatedCoord);
    FragColor=texColor*u_color;
}