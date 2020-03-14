#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec3 WHITE = vec3(1.0);
vec3 BLACK = vec3(0.0);
vec3 RED = vec3(1.0, 0.0, 0.0);
vec3 BLUE = vec3(0.0, 0.0, 1.0);
vec3 YELLOW = vec3(1.0, 1.0, 0.0);

struct Rect {
  float x;
  float y;
  float width;
  float height;
};

struct DrawRect {
  Rect rect;
  float stroke;
  vec3 fill;
};

bool point_in_rect(Rect r, vec2 p) {
  return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height;
}

bool on_wall(DrawRect dr, vec2 p, float s) {
  Rect r = dr.rect;

  Rect top = Rect(r.x, r.y + r.height - s, r.width, s);
  Rect right = Rect(r.x + r.width - s, r.y, s, r.height);
  Rect bottom = Rect(r.x, r.y, r.width, s);
  Rect left = Rect(r.x, r.y, s, r.height);

  return point_in_rect(top, p) ||
    point_in_rect(right, p) ||
    point_in_rect(bottom, p) ||
    point_in_rect(left, p);
}

// if on a wall, draw black.
// else if in area, draw fill.
// otherwise, draw white.
vec3 draw_rect(DrawRect dr, vec2 p) {
  if (point_in_rect(dr.rect, p)) {
    if (on_wall(dr, p, dr.stroke)) {
      return BLACK;
    } else {
      return dr.fill;
    }
  } else {
    return vec3(1.0);
  }
}

void main(){
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    vec3 color = vec3(1.0);

    float stroke = 0.04;
    DrawRect r1 = DrawRect(Rect(-stroke, 0.7, 0.34, 0.4), stroke, WHITE);
    DrawRect r2 = DrawRect(Rect(0.26, 0.34, 0.79, 0.7), stroke, RED);
    DrawRect r3 = DrawRect(Rect(-stroke, 0.34, 0.34, 0.4), stroke, WHITE);
    DrawRect r4 = DrawRect(Rect(-stroke, -stroke, 0.34, 0.42), stroke, BLUE);
    DrawRect r5 = DrawRect(Rect(0.85, -stroke, 0.2, 0.23), stroke, YELLOW);
    DrawRect r6 = DrawRect(Rect(0.85, 0.15, 0.2, 0.23), stroke, WHITE);

    vec3 dR1 = draw_rect(r1, st);
    vec3 dR2 = draw_rect(r2, st);
    vec3 dR3 = draw_rect(r3, st);
    vec3 dR4 = draw_rect(r4, st);
    vec3 dR5 = draw_rect(r5, st);
    vec3 dR6 = draw_rect(r6, st);

    color = dR1 * dR2 * dR3 * dR4 * dR5 * dR6;

    gl_FragColor = vec4(color, 1.0);
}
