vec3 palette( in float t)
{
    //A = (0.667, 0, 0); B = (0.5, -3, -3); C = (0.667, -0.333, -0.333); D = (0, 0.333, 0.333);
    vec3 a = vec3(0.667, 0.0, 0.0);
    vec3 b = vec3(0.5, -3.0, -3.0);
    vec3 c = vec3(0.667, -0.333, -0.333);
    vec3 d = vec3(0.0, 0.333, 0.333);

    return a + b*cos( 6.283185*(c*t+d) );
}

mat2 rot2D(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float sdPlane( vec3 p, vec3 n, float h )
{
    return dot(p,n) + h;
}

float map( vec3 p )
{

    p.xy *= rot2D(iTime*0.15);

    float t = 3.0;
    float planeD = sdPlane(p, vec3(0.0, 1.0, 0.0), t);
    float planeU = sdPlane(p, vec3(0.0, -1.0, 0.0), t);
    float planeL = sdPlane(p, vec3(1.0, 0.0, 0.0), t);
    float planeR = sdPlane(p, vec3(-1.0, 0.0, 0.0), t);
    return min(planeD, min(planeL, min(planeR, planeU)));
}

float rayMarch( vec3 ro , vec3 rd )
{
    float t = 0.0;
    float i;
    for (i = 0.0 ; i < 100.0 ; i++)
    {
        vec3 p = ro + rd * t;
        p.y += 0.3*sin(-t*0.8);
        p.x += 0.3*cos(t*0.75); 
        p.xy *= rot2D(t*0.5);
        float d = map(p);
        t += d;
        if (d < 0.001 || t > 100.0) break;
    }
    return i;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
    //Normalisation des coordonnées (-1 à 1)
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;


    vec3 ro = vec3(0.0);
    vec3 rd = normalize(vec3(vec2(uv.x+0.05*cos(iTime*0.3), uv.y-0.05*sin(iTime*0.3)), 1.0));
    vec3 col = vec3(0.0);

    float t = rayMarch(ro, rd);

    col += palette(t/90.0);
    //col += palette(1.0-(t/90.0));
    //col = vec3(1.0-(t/90.0));
    //col += vec3(t/90.0);

    fragColor = vec4(col, 1.0);
}