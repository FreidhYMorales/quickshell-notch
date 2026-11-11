#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 darkColor;
    vec4 lightColor;
    vec2 panelSize;
    float cornerRadius;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 pixel = texture(source, qt_TexCoord0);
    vec3 straight = pixel.a > 0.0 ? pixel.rgb / pixel.a : vec3(0.0);
    float luminance = dot(straight, vec3(0.2126, 0.7152, 0.0722));
    vec3 mapped = mix(darkColor.rgb, lightColor.rgb, luminance);
    vec2 halfSize = panelSize * 0.5;
    float radius = min(cornerRadius, min(halfSize.x, halfSize.y));
    vec2 q = abs(qt_TexCoord0 * panelSize - halfSize) - (halfSize - radius);
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float coverage = 1.0 - smoothstep(-1.0, 0.0, distance);
    fragColor = vec4(mapped * pixel.a, pixel.a) * qt_Opacity * coverage;
}
