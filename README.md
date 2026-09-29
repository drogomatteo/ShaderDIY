# ShaderDIY
Compilation de shader, réalisé avec Shader Toy (extension VSCode, WebGL 2.0)

## Comment Lire les fichiers .glsl ?

[L'OpenGL Shading Language](https://fr.wikipedia.org/wiki/OpenGL_Shading_Language) est un language de programmation utilisé par l'API OpenGL afin de tracer les vertex sur l'écran. Je connais actuellement trois méthodes pour lire ces fichiers (il existe certainement d'autres mais je ne suis pas assez renseigné) :
1. Sur **VSCode**, installez l'extension [Shader Toy](https://marketplace.visualstudio.com/items?itemName=stevensona.shader-toy). Puis, effectuez un click droit sur votre éditeur et sélectionnez l'option : *Shader Toy: Show GLSL Preview*. Une nouvelle fenêtre s'ouvre, vous montrant votre shader. Le shader change automatiquement lorsque vous changez du code.
2. Il est possible d'utiliser [Shadertoy](https://www.shadertoy.com/), un site web app qui permet de visualiser votre shader. Pour enregistrer votre shader, il faut créer un compte.
3. Pour chaque shader je crée une version HTML. Il suffit de l'installer et de l'ouvrir avec votre navigateur pour observer le shader.


## Mes shaders

- [*~/Rubik's Cube*](https://github.com/drogomatteo/ShaderDIY/tree/main/RubiksCube) : Un simple Rubik's cube qui tourne, avec gestion de lumière directionnelle.

- [*~/SolarSys*](https://github.com/drogomatteo/ShaderDIY/tree/main/SolarSys) : Notre système solaire, simplifié. Possibilité de se balader dans la galaxie avec la souris.

- [*~/InfiniteBox*](https://github.com/drogomatteo/ShaderDIY/tree/main/InfiniteBox) : Une scène générée à l'infini avec une boite. Inspiration : [An introduction to Raymarching](https://youtu.be/khblXafu7iA?si=TpIp4yjIA5VwHbGv)

- [*~/Nightime*](https://github.com/drogomatteo/ShaderDIY/tree/main/Nightime) : Une scène générée procéduralement. Inspiration : [An introduction to Shader Art](https://youtu.be/f4s1h2YETNY?si=KeBHw-I3-HhfKS43)

- [*~/Vortex*](https://github.com/drogomatteo/ShaderDIY/tree/main/Vortex) : Un vortex de couleur rouge-noir, le tout dans un fond blanc.

## Pour aller plus loin...

- [Inigo Quilez](https://iquilezles.org/) a travaillé (et travaille toujours) dans le domaine de l'informatique graphiste. Il a crée ce site internet dans le but de regrouper beaucoup d'outils mathémathiques utiles dans le domaine de l'infographie.
- [kishimisu](https://www.kishimisu.art/) est un créateur d'animations procédurales. Il possède une chaine youtube, où il explique le *raymarching* et une simple introduction dans la création de shader.
- [Sum And Product](http://www.youtube.com/@sumandproduct) est une petite chaine youtube allemande qui parle de géométrie dans l'espace, mais pas que. 
- [Sebastian Lague](http://www.youtube.com/@SebastianLague) tente de programmer tout et n'importe quoi, allant de la simulation d'un fluide, à des algorithmes de chemin le plus court (A*, Dijkstra) et l'analyse spectrale du son. une grande majorité de ses codes qu'il réalise sont sur son [GitHub](https://github.com/SebLague)