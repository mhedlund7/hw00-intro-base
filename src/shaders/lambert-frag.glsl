#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3(vec3 xyz)
{
    return vec3(
        fract(sin(dot(xyz.xyz ,vec3(12.9898, 78.233, 54.53))) * 43758.5453),
        fract(sin(dot(xyz.yxz ,vec3(14.7921, 48.012, 36.723))) * 39476.4739),
        fract(sin(dot(xyz.zyx ,vec3(37.5843, 64.327, 27.837))) * 84759.2857));
}

vec3 worleyColor3D(vec3 xyz)
{
    float minDist = 100.0;
    vec3 cellLocation = fract(xyz);
    vec3 cell = floor(xyz);
    vec3 color = vec3(0.0);
    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            for(int z = -1; z <= 1; z++) {
                vec3 adj = vec3(float(x), float(y), float(z));
                vec3 neighborCell = cell + adj;
                vec3 worleyPoint = random3(neighborCell);
                float dist = length(adj + worleyPoint - cellLocation);
                if (dist < minDist) {
                    minDist = dist;
                    color = random3(worleyPoint);
                }
            }
        }
    }
    return color;
}

void main()
{
    // Use Worley noise to get new color
    vec3 worleyColor = worleyColor3D(fs_Pos.xyz * 3.0);

    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // interpollate between worley color and u_Color
    diffuseColor = vec4(mix(diffuseColor.rgb, worleyColor, 0.5), diffuseColor.a);
    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
