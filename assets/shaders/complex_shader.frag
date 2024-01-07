precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform vec2 iMouse;
out vec4 fragColor;

// Ported from https://www.shadertoy.com/view/XlfGRj to Flutter

#define iterations 17
#define formuparam .53

#define volsteps 20
#define stepsize .1

#define zoom .800
#define tile .850
#define speed .010

#define brightness .0015
#define darkmatter .300
#define distfading .730
#define saturation .850

void main(){
    // Get coords and direction.
    vec2 uv=gl_FragCoord.xy/iResolution.xy-.5;
    uv.y*=iResolution.y/iResolution.x;
    vec3 dir=vec3(uv*zoom,1.);
    float time=iTime*speed+.25;
    
    // Mouse rotation.
    float a1=.5+iMouse.x/iResolution.x*2.;
    float a2=.8+iMouse.y/iResolution.y*2.;
    
    // Create rotation matrixes from the mouse angle.
    mat2 rot1=mat2(cos(a1),sin(a1),-sin(a1),cos(a1));
    mat2 rot2=mat2(cos(a2),sin(a2),-sin(a2),cos(a2));
    dir.xz*=rot1;
    dir.xy*=rot2;
    
    vec3 from=vec3(1.,.5,.5);
    from+=vec3(time*2.,time,-2.);
    from.xz*=rot1;
    from.xy*=rot2;
    
    // Volumetric rendering.
    float s=.1;
    float fade=1.;
    vec3 v=vec3(0.);
    for(int r=0;r<volsteps;r++){
        vec3 p=from+s*dir*.5;
        p=abs(vec3(tile)-mod(p,vec3(tile*2.)));// Tiling fold.
        
        float pa=0.;
        float a=0.;
        for(int i=0;i<iterations;i++){
            p=abs(p)/dot(p,p)-formuparam;// The magical formula.
            a+=abs(length(p)-pa);// The absolute sum of the average change.
            pa=length(p);
        }
        
        float dm=max(0.,darkmatter-a*a*.001);// Dark matter.
        a*=a*a;// Add contrast.
        if(r>6)fade*=1.-dm;// Dark matter, don't render when it is near.
        
        //v+=vec3(dm,dm*.5,0.);
        v+=fade;// Add the fading.
        v+=vec3(s,s*s,s*s*s*s)*a*brightness*fade;// Coloring based on distance.
        fade*=distfading;// Distance fading.
        s+=stepsize;
    }
    
    v=mix(vec3(length(v)),v,saturation);// Adjust color based on saturation.
    fragColor=vec4(v*.01,1.);
}