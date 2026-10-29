#version 460 core

#include <flutter/runtime_effect.glsl>

// Runs after a light blur of the backdrop: adds more blur the higher the pixel (a 7x7
// Gaussian whose spread shrinks to nothing 70% down), then fades the result out over the
// bottom 40%, so the blurred backdrop melts into the sharp one under it (srcOver).
uniform vec2 u_size;
// The scrim's height in physical pixels: the backdrop texture is the whole screen.
uniform float u_height;
// The extra blur's sigma at the top, in physical pixels.
uniform float u_sigma;
uniform sampler2D u_texture;

out vec4 fragColor;

void main() {
  vec2 xy = FlutterFragCoord().xy;
  float t = xy.y / u_height;
  float fade = 1.0 - smoothstep(0.6, 1.0, t);
  // Reduced visual effects: the blur before this does it all; only fade it out (one tap
  // instead of 49 a pixel).
  if (u_sigma <= 0.0) {
    fragColor = texture(u_texture, xy / u_size) * fade;
    return;
  }
  float sigma = u_sigma * (1.0 - smoothstep(0.0, 0.7, t));
  vec4 sum = vec4(0.0);
  float total = 0.0;
  for (int i = -3; i <= 3; i++) {
    for (int j = -3; j <= 3; j++) {
      // Steps of 0.6 sigma reach 1.8 sigma; the light blur before this fills the gaps.
      vec2 offset = vec2(float(i), float(j)) * 0.6;
      float w = exp(-0.5 * dot(offset, offset));
      sum += texture(u_texture, (xy + offset * sigma) / u_size) * w;
      total += w;
    }
  }
  fragColor = sum / total * fade;
}
