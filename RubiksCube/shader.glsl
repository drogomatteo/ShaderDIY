// Matrice de rotation autour de l'axe X
mat3 rotX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(
        1.0, 0.0, 0.0,
        0.0,   c,  -s,
        0.0,   s,   c
    );
}

// Matrice de rotation autour de l'axe Y
mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(
          c, 0.0,   s,
        0.0, 1.0, 0.0,
         -s, 0.0,   c
    );
}

// Matrice de rotation autour de l'axe Z
mat3 rotZ(float a) {
    float c = cos(a), s = sin(a);
    return mat3(
          c,  -s, 0.0,
          s,   c, 0.0,
        0.0, 0.0, 1.0
    );
}

// Angles de rotation globaux synchronisés
vec3 getAngles() {
    return vec3(0.885, iTime * 0.25, 0.885);
}

// Applique une translation T et une rotation R
vec3 transform(vec3 p, vec3 translation, vec3 angles) {
    // 1. Translation inverse
    vec3 q = p - translation;
    
    // 2. Matrice de rotation globale de l'objet (Yaw * Pitch * Roll)
    mat3 R = rotY(angles.y) * rotX(angles.x) * rotZ(angles.z);
    
    // 3. Multiplication par la transposée
    return transpose(R) * q;
}

//Box (https://iquilezles.org/)
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Boîte aux coins arrondis pour marquer les chanfreins et séparations des facettes
float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

/*
Construction de la scène :
- Box centré en (0,0,0), de coté 1.5 et sans rotation

Cette fonction retourne la distance entre un point et l'objet (SDFs)
*/
float map( vec3 p )
{
    vec3 pos = vec3(0.0);
    vec3 angles = getAngles();

    vec3 q = transform(p, pos, angles);

    // 1. Boîte englobante pour contraindre les cubes à un format 3x3x3
    float bound = sdBox(q, vec3(0.78));

    // 2. Répétition spatiale par grille de 0.52 (taille d'une cellule avec interstice)
    vec3 cell = clamp(round(q / 0.52), -1.0, 1.0);
    vec3 localP = q - cell * 0.52;

    // 3. Mini-cube arrondi représentant chaque "cubie"
    float cubie = sdRoundBox(localP, vec3(0.245), 0.035);

    // Intersection pour éliminer la répétition en dehors du 3x3x3
    return max(bound, cubie);
}

/*
Algorithme de ray marching
un rayon est envoyé dans une direction d
On avance jusqu'à :
- "croiser" un obstacle (la box)
- On dépasse l'affichage de la scène
Le croisement de la scène se fait lorsque le rayon est très proche de l'obstacle
*/

float rayMarch( vec3 ro , vec3 rd )
{
    float d0 = 0.0;
    for (int i = 0 ; i < 100 ; i++)
    {
        vec3 p = ro + rd * d0;
        float dS = map(p);
        d0 += dS;
        if (dS <= 0.001 || d0 >= 20.0)
        {
            break;
        }
    }

    return d0;
}
/*
Calcul de lumière et autre
*/
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    float d = map(p);
    vec3 n = d - vec3(
        map(p - e.xyy),
        map(p - e.yxy),
        map(p - e.yyx)
    );
    return normalize(n);
}

// Couleurs officielles selon l'orientation locale des faces
vec3 getRubikColor(vec3 localPos, vec3 localNormal) {
    vec3 aNorm = abs(localNormal);

    // Repérage dans le cubie individuel (-1, 0, 1)
    vec3 cell = clamp(round(localPos / 0.52), -1.0, 1.0);
    vec3 pInCubie = abs(localPos - cell * 0.52);

    // Si la face regarde vers une direction où le cubie n'est pas en bordure, c'est l'intérieur/fente
    if (dot(cell, localNormal) < 0.8) {
        return vec3(0.02);
    }

    // Sélection de la couleur selon la normale principale et découpe de l'autocollant
    if (aNorm.y > aNorm.x && aNorm.y > aNorm.z) {
        if (pInCubie.x > 0.20 || pInCubie.z > 0.20) return vec3(0.02);
        if (localNormal.y > 0.0) {
            return vec3(0.95, 0.95, 0.95); // Blanc
        } else {
            return vec3(0.95, 0.85, 0.05); // Jaune
        }
    } else if (aNorm.x > aNorm.z) {
        if (pInCubie.y > 0.20 || pInCubie.z > 0.20) return vec3(0.02);
        if (localNormal.x > 0.0) {
            return vec3(0.85, 0.05, 0.05); // Rouge
        } else {
            return vec3(0.95, 0.40, 0.02); // Orange
        }
    } else {
        if (pInCubie.x > 0.20 || pInCubie.y > 0.20) return vec3(0.02);
        if (localNormal.z > 0.0) {
            return vec3(0.05, 0.35, 0.85); // Bleu
        } else {
            return vec3(0.05, 0.65, 0.15); // Vert
        }
    }
}

/*
Affichage de la box 
*/
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Coordonnées d'écran centrées (-1 à 1) avec correction du ratio
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Caméra : position (ro) et direction du rayon pour ce pixel (rd)
    vec3 ro = vec3(0.0, 0.0, -3.5);
    vec3 rd = normalize(vec3(uv, 1.0));

    // Lancer du rayon
    float d = rayMarch(ro, rd);

    // Fond par défaut
    vec3 col = vec3(0.003, 0.003, 0.003);

    // Si on a touché la boîte
    if (d < 20.0) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);

        // 1. Lumière directionnelle et sa couleur
        vec3 lightDir = normalize(vec3(1.0, 1.5, -1.5));
        vec3 lightColor = vec3(1.0, 0.95, 0.95); // Couleur de la lumière (modifiable ici)

        // 2. Calculs d'incidence
        float diff = max(dot(n, lightDir), 0.0); // Éclairage diffus (Lambert)
        float amb = 0.02;                        // Lumière ambiante très faible pour des ombres profondes
        vec3 ambientColor = vec3(0.23, 0.23, 0.23); // Lueur ambiante d'ombre

        // 3. Reflet spéculaire (aspect plastique brillant)
        vec3 h = normalize(lightDir - rd);
        float spec = pow(max(dot(n, h), 0.0), 32.0);

        // 4. Repérage local pour le sticker et la couleur
        vec3 angles = getAngles();
        mat3 R = rotY(angles.y) * rotX(angles.x) * rotZ(angles.z);
        vec3 localP = transpose(R) * p;
        vec3 localN = transpose(R) * n;

        vec3 objColor = getRubikColor(localP, localN);

        // 5. Combinaison de la lumière diffuse, ambiante et spéculaire
        vec3 diffuseLighting = lightColor * diff;
        vec3 ambientLighting = ambientColor * amb;
        col = objColor * (diffuseLighting + ambientLighting) + lightColor * spec * 0.3;
    }

    // Correction Gamma basique
    col = pow(col, vec3(1.0 / 2.2));

    fragColor = vec4(col, 1.0);
}