// ==============================================================================
// 1. UTILITAIRES ET BRUIT PROCÉDURAL (NOISE)
// ==============================================================================

// Fonction de hachage basique pour l'aléatoire
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Bruit de valeur 3D (Value Noise)
float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

// Mouvement Brownien Fractal (FBM) pour des textures riches
float fbm(vec3 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p = p * 2.02;
    f += 0.2500 * noise(p); p = p * 2.03;
    f += 0.1250 * noise(p);
    return f;
}

// Génère un ciel étoilé avec la bande de la Voie Lactée
vec3 getSky(vec3 rd) {
    // 1. Fond cosmique de base
    float dust = fbm(rd * 6.0);
    vec3 skyCol = mix(vec3(0.0001, 0.0001, 0.0005), vec3(0.01, 0.005, 0.03), dust);

    // 2. Définition géométrique de la Voie Lactée
    // On crée un disque incliné dans le ciel en projetant la direction rd
    float band = abs(dot(rd, normalize(vec3(0.0, 10.0, -10.0)))); 
    // smoothstep inverse la valeur : 1.0 au centre de la bande, 0.0 sur les bords
    float mwMask = smoothstep(0.70, 0.0, band);

    // 3. Nuages de gaz lumineux et stries de poussière sombre
    float gasClouds = fbm(rd * 6.0); 
    float darkDust = fbm(rd * 0.12215); // Bruit plus fin pour la poussière opaque
    
    // Coloration : un dégradé du bleu nuit profond vers un violet/rosé au centre des nuages
    vec3 mwColor = mix(vec3(0.02, 0.05, 0.15), vec3(0.25, 0.10, 0.20), gasClouds);
    mwColor *= mwMask; // On restreint ces gaz à la bande galactique
    mwColor -= darkDust * mwMask * 0.4; // Soustraction de lumière pour les veines de poussière noire
    
    // Ajout de la lueur galactique au fond du ciel
    skyCol += max(mwColor * 0.5, 0.0);

    // 4. Couche d'étoiles 1 : La densité s'adapte à la Voie Lactée
    float star1 = hash(rd * 100.0);
    // Magie ici : hors galaxie le seuil est 0.995, dans la galaxie il chute à 0.980 (beaucoup plus d'étoiles)
    float threshold = mix(0.998, 0.985, mwMask); 
    skyCol += vec3(1.0, 0.95, 0.9) * smoothstep(threshold, 1.0, star1) * (1.0 + gasClouds * 2.0);

    // 5. Couche d'étoiles 2 : Grosses étoiles bleutées parsemées (répartition uniforme)
    float star2 = hash(rd * 400.0 + vec3(12.0)); 
    skyCol += vec3(0.6, 0.8, 1.0) * smoothstep(0.998, 1.0, star2) * 1.5;

    return skyCol;
}

mat2 rot2D(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// ==============================================================================
// 2. FONCTIONS DE DISTANCE SIGNÉE (SDF) & GÉOMÉTRIE
// ==============================================================================

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Combine la distance la plus courte et conserve l'ID du matériau
vec2 opU(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdAnnulus3D(vec3 p, float r1, float r2) {
    float rho = length(p.xy);
    float dr = max(max(r1 - rho, rho - r2), 0.0);
    return length(vec2(dr, p.z));
}

// ==============================================================================
// 3. CONSTRUCTION DU SYSTÈME SOLAIRE (MAP)
// ==============================================================================

vec2 map(vec3 p) {
    // Rayons
    float RSun = 4.00, RMer = 0.15, RVen = 0.30, RTer = 0.35, RLun = 0.10;
    float RMar = 0.20, RJup = 1.20, RSat = 1.00, RInt = 1.40, RExt = 2.20;
    float RUra = 0.60, RNep = 0.58;

    // Multiplicateur global de temps
    float t = iTime * 0.05;

    // 0. Le Soleil (ID: 0.0)
    vec3 pSun = p; 
    pSun.xz *= rot(t * 0.1);
    vec2 res = vec2(sdSphere(pSun, RSun), 0.0);

    // 1. Mercure (ID: 1.0)
    vec3 pMer = p; 
    pMer.xz *= rot(t * 2.0); pMer.x -= 6.0; pMer.xz *= rot(t * 0.2);
    res = opU(res, vec2(sdSphere(pMer, RMer), 1.0));

    // 2. Vénus (ID: 2.0)
    vec3 pVen = p; 
    pVen.xz *= rot(t * 1.5); pVen.x -= 9.0; pVen.xz *= rot(t * -0.1); 
    res = opU(res, vec2(sdSphere(pVen, RVen), 2.0));

    // 3. La Terre (ID: 3.0)
    vec3 pTer = p; 
    pTer.xz *= rot(t * 1.0); pTer.x -= 12.0;
    vec3 pLun = pTer; // On sauvegarde l'espace Terre pour la Lune
    pTer.xz *= rot(t * 2.0); 
    res = opU(res, vec2(sdSphere(pTer, RTer), 3.0));

    // 4. La Lune (ID: 4.0)
    pLun.xz *= rot(t * 3.0); pLun.x -= 1.5; pLun.xz *= rot(t * 0.5);
    res = opU(res, vec2(sdSphere(pLun, RLun), 4.0));

    // 5. Mars (ID: 5.0)
    vec3 pMar = p; 
    pMar.xz *= rot(t * 0.8); pMar.x -= 15.0; pMar.xz *= rot(t * 1.9);
    res = opU(res, vec2(sdSphere(pMar, RMar), 5.0));

    // 6. Jupiter (ID: 6.0)
    vec3 pJup = p; 
    pJup.xz *= rot(t * 0.4); pJup.x -= 22.0; pJup.xz *= rot(t * 5.0);
    res = opU(res, vec2(sdSphere(pJup, RJup), 6.0));

    // 7 & 8. Saturne (ID: 7.0) et son anneau (ID: 8.0)
    vec3 pSat = p; 
    pSat.xz *= rot(t * 0.25); pSat.x -= 30.0; pSat.xy *= rot(0.4);
    vec3 pRing = pSat;
    pSat.xz *= rot(t * 4.5);
    res = opU(res, vec2(sdSphere(pSat, RSat), 7.0));
    res = opU(res, vec2(sdAnnulus3D(pRing.xzy, RInt, RExt), 8.0));

    // 9. Uranus (ID: 9.0)
    vec3 pUra = p; 
    pUra.xz *= rot(t * 0.15); pUra.x -= 38.0; 
    pUra.xy *= rot(1.57); // Couchée sur le côté
    pUra.xz *= rot(t * -3.0); 
    res = opU(res, vec2(sdSphere(pUra, RUra), 9.0));

    // 10. Neptune (ID: 10.0)
    vec3 pNep = p; 
    pNep.xz *= rot(t * 0.1); pNep.x -= 44.0; pNep.xz *= rot(t * 3.5);
    res = opU(res, vec2(sdSphere(pNep, RNep), 10.0));

    return res;
}

// ==============================================================================
// 4. RAYMARCHING ET NORMALES
// ==============================================================================

vec2 rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    float matID = -1.0;
    for (int i = 0; i < 200; i++) {
        vec3 p = ro + rd * dO;
        vec2 res = map(p);
        dO += res.x;
        matID = res.y;
        if (res.x < 0.001 || dO > 250.0) break; // Distance max augmentée à 250
    }
    return vec2(dO, matID);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    float d = map(p).x;
    vec3 n = d - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
    return normalize(n);
}

// ==============================================================================
// 5. RENDU (MAIN)
// ==============================================================================

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 m = (iMouse.xy * 2.0 - iResolution.xy) / iResolution.y;

    // Caméra
    vec3 ro = vec3(50.0, 30.0, 0.0);
    vec3 lookAt = vec3(0.0, 0.0, 0.0);

    // Système de vue
    vec3 f = normalize(lookAt - ro);
    vec3 r = normalize(cross(vec3(0.0, 1.0, 0.0), f));
    vec3 u = cross(f, r);
    vec3 rd = normalize(uv.x * r + uv.y * u + 1.2 * f);

    ro.xz *= rot2D(-2.0*m.x); 
    rd.xz *= rot2D(-2.0*m.x);

    vec2 hit = rayMarch(ro, rd);
    float d = hit.x;
    float matID = hit.y;

    vec3 col = getSky(rd);

    if (d < 250.0) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);
        
        // La lumière vient de l'origine (0,0,0) là où se trouve le Soleil
        vec3 lightDir = normalize(-p);
        float diff = max(dot(n, lightDir), 0.0);
        
        vec3 albedo = vec3(1.0);

        // --- CHOIX DE LA TEXTURE SELON L'OBJET TOUCHÉ ---
        
        if (matID == 0.0) {
            // Soleil : Bouillonnant, n'utilise pas l'ombre
            float nVal = fbm(p * 2.0 - iTime * 0.5);
            albedo = mix(vec3(1.0, 0.2, 0.0), vec3(1.0, 0.9, 0.2), nVal);
            col = albedo; 
        } 
        else {
            if (matID == 1.0 || matID == 4.0) {
                // Mercure & Lune : Cratères rugueux
                float nVal = fbm(p * 10.0);
                albedo = vec3(0.5) * (0.6 + 0.4 * nVal);
            } 
            else if (matID == 2.0) {
                // Vénus : Atmosphère épaisse
                float nVal = fbm(p * 3.0);
                albedo = mix(vec3(0.8, 0.5, 0.2), vec3(0.9, 0.7, 0.4), nVal);
            }
            else if (matID == 3.0) {
                // Terre : Océans, continents et un peu de nuages
                float nVal = fbm(p * 4.0);
                albedo = mix(vec3(0.1, 0.3, 0.7), vec3(0.2, 0.6, 0.2), smoothstep(0.4, 0.6, nVal));
            } 
            else if (matID == 5.0) {
                // Mars : Rouge/Ocre avec du relief
                float nVal = fbm(p * 4.0);
                albedo = mix(vec3(0.7, 0.2, 0.1), vec3(0.9, 0.4, 0.2), nVal);
            }
            else if (matID == 6.0) {
                // Jupiter : Bandes gazeuses perturbées par le FBM
                float bands = sin(p.y * 12.0 + fbm(p * 3.0) * 4.0);
                albedo = mix(vec3(0.7, 0.5, 0.3), vec3(0.9, 0.8, 0.6), bands * 0.5 + 0.5);
            }
            else if (matID == 7.0) {
                // Saturne : Bandes gazeuses plus douces
                albedo = vec3(0.9, 0.8, 0.6) * (0.8 + 0.2 * sin(p.y * 6.0));
            }
            else if (matID == 8.0) {
                // Anneau de Saturne : Stries radiales
                float rad = length(p.xz);
                float ringPattern = cos(rad * 10.0 + fbm(p * 3.0) * 0.5);
                albedo = vec3(0.8, 0.7, 0.5) * (0.5 + 0.5 * ringPattern);
            }
            else if (matID == 9.0) {
                // Uranus : Bleu pâle unifié
                float nVal = fbm(p * 2.0);
                albedo = mix(vec3(0.5, 0.8, 0.9), vec3(0.6, 0.9, 1.0), nVal);
            }
            else if (matID == 10.0) {
                // Neptune : Bleu sombre avec des tempêtes
                float bands = sin(p.y * 8.0 + fbm(p * 2.0) * 2.0);
                albedo = mix(vec3(0.1, 0.2, 0.8), vec3(0.2, 0.4, 0.9), bands * 0.5 + 0.5);
            }

            // Calcul final de la lumière pour toutes les planètes
            // 1. Lumière diffuse
            col = albedo * diff * 1.5;
            
            // 2. Ajout d'une très légère lumière ambiante globale pour qu'elles ne soient pas 100% noires
            col += albedo * 0.008; 
        }
    }

    // Correction Gamma pour un rendu plus naturel
    fragColor = vec4(pow(col, vec3(0.4545)), 1.0);
}