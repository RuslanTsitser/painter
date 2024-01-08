#version 460 core

#include<flutter/runtime_effect.glsl>

precision mediump float;

uniform float u_width;// Line width
uniform float u_angle;// Line angle
uniform vec4 u_color;// Input color (r,g,b,a)
uniform vec2 u_resolution;// Canvas size (width,height)
uniform sampler2D u_texture;// Texture sampler

out vec4 FragColor;

void main(){
    // Convert the pixel position to a coordinate from 0 to 1
    vec2 st=gl_FragCoord.xy/u_resolution;
    
    // Rotate by angle
    float angle=radians(u_angle);// Convert angle to radians
    mat2 rot=mat2(cos(angle),-sin(angle),
    sin(angle),cos(angle));
    vec2 rotated=rot*(st-.5)+.5;// Rotate around the center
    
    // Calculate the position in pixel units
    float xPos=rotated.x*u_resolution.x;
    float lineWidth=u_width;
    float interval=lineWidth*1;
    
    // Sample the texture color
    vec4 texColor=texture(u_texture,st);
    
    // Set the color of the pixel based on the line logic and apply texture color
    if(mod(xPos,interval)<lineWidth){
        // Draw a line with the texture color
        FragColor=texColor*u_color;// Multiply by input color for tinting effect
    }else{
        // Make other pixels transparent or black
        FragColor=vec4(0.,0.,0.,1.);
    }
}
