#include<flutter/runtime_effect.glsl>

uniform vec2 iResolution;// Canvas size (width,height)
uniform float iTime;// Time in seconds since load

out vec4 fragColor;// output colour for Flutter, like gl_FragColor

void main(){
    vec2 st=FlutterFragCoord().xy/iResolution.xy;
    st.x*=iResolution.x/iResolution.y;
    
    vec3 color=vec3(0.);
    color=vec3(st.x,st.y,abs(sin(iTime)));
    
    fragColor=vec4(color,1.);
}