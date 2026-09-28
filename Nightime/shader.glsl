vec3 palette( in float t)
{
    //[[0.138 -0.492 -0.762] [0.108 0.918 -1.192] [3.138 3.138 -2.872] [0.648 1.098 0.667]]
    vec3 a = vec3(0.015, -0.192, -1.162);
    vec3 b = vec3(0.040, 0.218, -1.192);
    vec3 c = vec3(3.138, 3.138, -2.872);
    vec3 d = vec3(0.648, 1.098, -0.667);

    return a + b*cos( 6.283185*(c*t+d) );
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    // normalisation des coordonnées (-1 à 1)
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;
    vec3 finalcol = vec3(0.0);

    for (int i = 0 ; i < 3 ; i++){
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv);
        vec3 col = palette(length(uv0) - iTime*0.10);

        d = sin(d*4.0 + iTime)/4.0;
        d = abs(d);

        d = 0.02/d;
        finalcol += col * d;
    }
    fragColor = vec4(finalcol, 1.0);
}