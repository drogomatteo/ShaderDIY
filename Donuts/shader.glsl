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

/* Sigmoid function */

float sigmoid ( float x ) 
{
    return (1./(1.+exp(-x)));
}

/* Coordinate and unit utils */
vec2 coord(in vec2 p) {
    p = p / u_resolution.xy;
    // correct aspect ratio
    if (u_resolution.x > u_resolution.y) {
        p.x *= u_resolution.x / u_resolution.y;
        p.x += (u_resolution.y - u_resolution.x) / u_resolution.y / 2.0;
    } else {
        p.y *= u_resolution.y / u_resolution.x;
        p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    }
    // centering
    p -= 0.5;
    p *= vec2(-1.0, 1.0);
    return p;
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

/* Smooth Union */
float opSmoothUnion( float a, float b, float k )
{
  k *= 4.0;
  float h = max(k-abs(a-b),0.0);
  return min(a, b) - h*h*0.25/k;
}

/* Torus */

#define Torus_R         vec2(5., 2.*sigmoid(u_time-3.0))

float torus ( vec3 x )
{
    x = rotateX(x, PI/4.*sigmoid(u_time-4.0));
    x = rotateY(x, -PI/8.*sigmoid(u_time-4.0));
    x = rotateZ(x, -PI/8.*sigmoid(u_time-4.0));

    float majorAngle = atan(x.z, x.x);
    float minorAngle = atan(x.y, length(x.xz) - Torus_R.x);
    float majorLines = abs(sin(majorAngle * 16.0 + u_time/8.));
    float minorLines = abs(sin(minorAngle * 8.0 + u_time));
    return 1.0 - smoothstep(0.0, 0.08, opSmoothUnion(majorLines, minorLines, 0.03));
}


/*Signed Distance Field 3D shapes*/

float sdTorus ( vec3 p , vec2 t ){
    vec2 q = vec2(length(p.xz)-t.x , p.y);
    return length(q)-t.y;
}

/*Map function*/
float map ( vec3 p ){

    p = rotateX(p, PI/4.*sigmoid(u_time-4.0));
    p = rotateY(p, -PI/8.*sigmoid(u_time-4.0));
    p = rotateZ(p, -PI/8.*sigmoid(u_time-4.0));

    float Torus = sdTorus(p, Torus_R);
    return Torus;
}

/*Ray Marching function*/

vec2 rayMarch ( vec3 ro , vec3 rd){
    float d = 0.;
    float j = 0.;
    for (float i = 0. ; i < 200. ; i++){
        vec3 p = ro + rd * d;
        float t = map(p);
        d += t;
        j ++;
        if (d > 20. || t < 0.01) break;
    }
    return vec2(j, d);
}

void main() {
    vec2 uv = coord(gl_FragCoord.xy);
    vec2 ms = coord(u_mouse);
    vec3 color = vec3(0.);

    vec3 ro = vec3(1.4, -0.5, -6.7-10.*(1.-sigmoid(u_time-3.0)));
    vec3 rd = vec3(uv.x-0.3, uv.y, 1.);

    vec2 result = rayMarch(ro, rd);

    float i = result.x;
    float dist = result.y;

    if (dist <= 20.){
        float percent = dist/20.;
        vec3 hitPoint = ro + rd * dist;
        float grid = torus(hitPoint);
        vec3 surfaceColor = mix(vec3(0.1, 0.025, 0.0), vec3(1.0, 0.65, 0.0), grid);
        color = surfaceColor * (0.35 + 0.65 * percent);
    }
    else{
        float percent = i/20.;
        vec3 surfaceColor = mix(vec3(0.1, 0.025, 0.0), vec3(1.0, 0.65, 0.0), length(uv));
    }
    gl_FragColor = vec4(color, 1.);
}