// Pure ear geometry that builds SVG path strings for `PathSvg`.
// y = 0 is the top screen edge. An "ear" is CONCAVE: the edge that touches the
// screen flares outward past the body, then a quarter circle (cubic, KAPPA)
// centred on that screen edge curves down into the body's side. Square
// anchors touch both screen edges; "round" corners are convex.

const KAPPA = 0.5523; // cubic approximation of a quarter circle

const ANCHORS = ["topLeft", "topRight", "bottomLeft", "bottomRight"];

const num = (n) => Number(n.toFixed(3));
const pt = (x, y) => `${num(x)} ${num(y)}`;
const clampTo = (v, max) => Math.max(0, Math.min(v, max));

// Segments are plain arrays so a path can be mirrored before serialising:
// ["M", x, y] | ["L", x, y] | ["C", x1, y1, x2, y2, x, y] | ["A", r, sweep, x, y]
function serialise(segs) {
  const parts = segs.map((s) => {
    if (s[0] === "A") {
      return `A ${num(s[1])} ${num(s[1])} 0 0 ${s[2]} ${pt(s[3], s[4])}`;
    }
    const pairs = [];
    for (let i = 1; i < s.length; i += 2) pairs.push(pt(s[i], s[i + 1]));
    return `${s[0]} ${pairs.join(" ")}`;
  });
  return parts.concat("Z").join(" ");
}

function serialiseOpen(segs) {
  return serialise(segs).replace(/ Z$/, "");
}

// Convex bottom-right style arc, skipped when the radius is zero.
const arc = (r, sweep, x, y) => (r > 0 ? [["A", r, sweep, x, y]] : []);

/** Concave notch hanging from the top edge: ears at the top, round bottom. */
export function notchPath(w, h, er, cr) {
  const e = clampTo(er, Math.min(h, w / 2));
  const c = clampTo(cr, Math.min(h - e, w / 2 - e));
  const k = KAPPA * e;
  const segs = [["M", 0, 0], ["L", w, 0]]
    .concat([["C", w - k, 0, w - e, e - k, w - e, e]])
    .concat([["L", w - e, h - c]], arc(c, 1, w - e - c, h))
    .concat([["L", e + c, h]], arc(c, 1, e, h - c))
    .concat([["L", e, e]])
    .concat([["C", e, e - k, k, 0, 0, 0]]);
  return serialise(segs);
}

/** One continuous open contour around every exposed edge of a centred notch. */
export function notchOutlinePath(w, h, er, cr) {
  const e = clampTo(er, Math.min(h, w / 2));
  const c = clampTo(cr, Math.min(h - e, w / 2 - e));
  const b = c > 1 ? h - 1 : h;
  const r = Math.min(c, b - (h - c));
  const k = KAPPA * e;
  const segs = [["M", 0, 0], ["C", k, 0, e, e - k, e, e]]
    .concat([["L", e, h - c]], arc(r, 0, e + r, b))
    .concat([["L", w - e - r, b]], arc(r, 0, w - e, h - c))
    .concat([["L", w - e, e]])
    .concat([["C", w - e, e - k, w - k, 0, w, 0]]);
  return serialiseOpen(segs);
}

// Mirror helpers: a single-axis flip reverses arc sweep, two flips restore it.
function mirror(segs, w, h, flipX, flipY) {
  const flips = (flipX ? 1 : 0) + (flipY ? 1 : 0);
  return segs.map((s) => {
    const out = [s[0]];
    if (s[0] === "A") {
      out.push(s[1], flips === 1 ? 1 - s[2] : s[2]);
    }
    const from = s[0] === "A" ? 3 : 1;
    for (let i = from; i < s.length; i += 2) {
      out.push(flipX ? w - s[i] : s[i], flipY ? h - s[i + 1] : s[i + 1]);
    }
    return out;
  });
}

/**
 * Anchor corner square (touches both screen edges), its two neighbours are
 * concave ears flaring along those edges, the opposite corner is convex round.
 * Built for topLeft and mirrored for the other anchors.
 */
export function cornerPath(w, h, anchor, er, cr) {
  if (ANCHORS.indexOf(anchor) < 0) return null;
  const e = clampTo(er, Math.min(h, w) / 2);
  const c = clampTo(cr, Math.min(h - 2 * e, w - 2 * e));
  const k = KAPPA * e;
  const segs = [["M", 0, 0], ["L", w, 0]]
    .concat([["C", w - k, 0, w - e, e - k, w - e, e]])
    .concat([["L", w - e, h - e - c]], arc(c, 1, w - e - c, h - e))
    .concat([["L", e, h - e]])
    .concat([["C", e - k, h - e, 0, h - k, 0, h]])
    .concat([["L", 0, 0]]);
  return serialise(
    mirror(segs, w, h, anchor.endsWith("Right"), anchor.startsWith("bottom")),
  );
}

/** One continuous open contour around exposed edges of a top corner notch. */
export function cornerOutlinePath(w, h, anchor, er, cr) {
  if (anchor !== "topLeft" && anchor !== "topRight") return null;
  const e = clampTo(er, Math.min(h, w) / 2);
  const c = clampTo(cr, Math.min(h - 2 * e, w - 2 * e));
  const k = KAPPA * e;
  const segs = [["M", w, 0], ["C", w - k, 0, w - e, e - k, w - e, e]]
    .concat([["L", w - e, h - e - c]])
    .concat(arc(c, 1, w - e - c, h - e))
    .concat([["L", e, h - e]])
    .concat([["C", e - k, h - e, 0, h - k, 0, h]]);
  return serialiseOpen(
    anchor === "topLeft" ? segs : mirror(segs, w, h, true, false),
  );
}
