/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

/* Color palette */
vec3 palette( in float t)
{
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(0.5, 0.5, 0.5);
    vec3 d = vec3(0.1, 0.1, 0.1);

    return a + b*cos( TWO_PI*(c*t+d) );
}

/* Math 2D Transformations */
mat2 rotate2d(in float angle){
    return mat2(cos(angle),-sin(angle), sin(angle), cos(angle));
}

/* Math 3D Transformations */

const mat4 projection = mat4(
    vec4(3.0 / 4.0, 0.0, 0.0, 0.0),
    vec4(     0.0, 1.0, 0.0, 0.0),
    vec4(     0.0, 0.0, 0.5, 0.5),
    vec4(     0.0, 0.0, 0.0, 1.0)
);

mat4 scale = mat4(
    vec4(4.0 / 3.0, 0.0, 0.0, 0.0),
    vec4(     0.0, 1.0, 0.0, 0.0),
    vec4(     0.0, 0.0, 1.0, 0.0),
    vec4(     0.0, 0.0, 0.0, 1.0)
);

mat4 rotation = mat4(
    vec4(1.0,          0.0,         0.0, 	0.0),
    vec4(0.0,  cos(u_time), sin(u_time),  	0.0),
    vec4(0.0, -sin(u_time), cos(u_time),  	0.0),
    vec4(0.0,          0.0,         0.0, 	1.0)
);

mat4 rotationAxis(float angle, vec3 axis) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotateX(vec3 p, float angle) {
    mat4 rmy = rotationAxis(angle, vec3(1.0, 0.0, 0.0));
    return (vec4(p, 1.0) * rmy).xyz;
}

vec3 rotateY_(vec3 p, float angle) {
    mat4 rmy = rotationAxis(angle, vec3(0.0, 1.0, 0.0));
    return (vec4(p, 1.0) * rmy).xyz;
}

vec3 rotateZ(vec3 p, float angle) {
    mat4 rmy = rotationAxis(angle, vec3(0.0, 0.0, 1.0));
    return (vec4(p, 1.0) * rmy).xyz;
}

vec3 rotateY(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    mat4 r = mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
    return (vec4(p, 1.0) * r).xyz;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map( vec3 p ){
    float clapping = max(1.0, 8.0/u_time);

    p.z += u_time;

    p = mod(p,2.0*clapping) - 1.0*clapping;

    float box = sdBox(p, vec3(0.5,0.5,0.5));
    return box;
}

float rayMarch( vec3 ro , vec3 rd ) {
    float t = 0.0;
    for (float i = 0.0; i < 255.0; i++) {
        vec3 p = ro + rd * t;

        float d = map(p);
        t += d;
        if (d < 0.001 || t > 15.) return i;
    }
}

void main() {
    vec3 color = vec3(0.0);
    float i = 4.0;
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / u_resolution.y;
    vec2 ms = (u_mouse.xy *2.0 - u_resolution.xy)/u_resolution.y;
    vec3 ro = vec3(ms/3., -5.0);
    vec3 rd = normalize(vec3(uv, 1.0));

    float ray = rayMarch(ro, rd);

    color += palette(1.0-(ray/100.));

    gl_FragColor = vec4(color, 1.0);
}