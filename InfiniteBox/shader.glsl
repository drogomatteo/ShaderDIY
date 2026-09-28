vec3 palette( in float t)
{
    //palette A = (0.687, -1.103, 0.864); B = (-0.682, 0.957, 1.214); C = (0.182, -0.875, 0.376); D = (-0.993, -0.329, 0.246);
    vec3 a = vec3(0.687, -1.103, 0.864);
    vec3 b = vec3(-0.682, 0.957, 1.214);
    vec3 c = vec3(0.242, -0.875, 0.376);
    vec3 d = vec3(-0.993, -0.329, 0.266);

    return a + b*cos( 6.283185*(c*t+d) );
}

mat2 rot2D(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere( vec3 p, float r )
{
  return length(p) - r;
}

float map( vec3 p ){
    p.x += iTime*0.0006;
    p.xy *= rot2D(iTime*0.05);
    p.z += iTime*0.2;

    p.xy = (fract(p.xy) - 0.5);
    p.z = mod(p.z, 0.25) - 0.125;

    /*
    float sphere = sdSphere(p, 0.15);
    return sphere;
    */

    
    float box = sdBox(p, vec3(0.05,0.1,0.09));
    return box;
    

    /*
    float torus = sdTorus(p, vec2(0.0005, 0.1));
    return torus;
    */
}

float rayMarch( vec3 ro , vec3 rd ) {
    float t = 0.0;
    float i;
    for (i = 0.0; i < 100.0; i++) {
        vec3 p = ro + rd * t;

        p.xy *= rot2D(t*0.08);

        p.y += 0.15*sin(t);
        //p.x += 0.05*cos(t);

        float d = map(p);
        t += d;
        if (d < 0.001 || t > 50.0) break;
    }
    return i;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    // normalisation des coordonnées (-1 à 1)
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;


    //Valeur initiale
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    vec3 col = vec3(0);

    float t = rayMarch(ro, rd);

    col = vec3(palette((t)/100.0));

    fragColor = vec4(col, 1.0);
}