// Pure ear geometry that builds SVG path strings for `PathSvg`.
// An "ear" is a tangent-continuous cubic between two edge endpoints. A single
// arc centred on the true corner would kink 90 degrees against both edges.

const EAR_REACH = 0.6; // k = radius * EAR_REACH, clamped to the free edge
const EAR_PULL = 1.3; // d = radius * EAR_PULL, control point travel

const DIRS = {
  topLeft: { enter: { x: 0, y: -1 }, leave: { x: 1, y: 0 } },
  topRight: { enter: { x: 1, y: 0 }, leave: { x: 0, y: 1 } },
  bottomRight: { enter: { x: 0, y: 1 }, leave: { x: -1, y: 0 } },
  bottomLeft: { enter: { x: -1, y: 0 }, leave: { x: 0, y: -1 } },
};
// Clockwise order. The path starts at the end of topLeft and closes with it.
const ORDER = ["topLeft", "topRight", "bottomRight", "bottomLeft"];
const ADJACENT = {
  topLeft: ["topRight", "bottomLeft"],
  topRight: ["topLeft", "bottomRight"],
  bottomRight: ["topRight", "bottomLeft"],
  bottomLeft: ["topLeft", "bottomRight"],
};

/** Ported unchanged from the old EarCurve.js. Dirs are unit vectors. */
export function earCubic(
  cornerX,
  cornerY,
  r,
  k,
  d,
  enteringDir,
  leavingDir,
  extendEntering,
) {
  const reachIn = extendEntering ? r + k : r;
  const reachOut = extendEntering ? r : r + k;
  const startX = cornerX - enteringDir.x * reachIn;
  const startY = cornerY - enteringDir.y * reachIn;
  const endX = cornerX + leavingDir.x * reachOut;
  const endY = cornerY + leavingDir.y * reachOut;
  return {
    startX,
    startY,
    endX,
    endY,
    c1x: startX + enteringDir.x * d,
    c1y: startY + enteringDir.y * d,
    c2x: endX - leavingDir.x * d,
    c2y: endY - leavingDir.y * d,
  };
}

const num = (n) => Number(n.toFixed(3));
const pt = (x, y) => `${num(x)} ${num(y)}`;
const clamp = (v, w, h) => Math.max(0, Math.min(v, w / 2, h));

// types: { corner: "square" | "ear" | "round" }
function buildPath(w, h, er, cr, types) {
  const e = clamp(er, w, h);
  const c = clamp(cr, w, h);
  const radius = (t) => (t === "ear" ? e : t === "round" ? c : 0);
  const at = {
    topLeft: [0, 0],
    topRight: [w, 0],
    bottomRight: [w, h],
    bottomLeft: [0, h],
  };
  const parts = ORDER.map((name, i) => {
    const prev = ORDER[(i + 3) % 4];
    const next = ORDER[(i + 1) % 4];
    const { enter, leave } = DIRS[name];
    const [x, y] = at[name];
    const r = radius(types[name]);
    if (types[name] === "ear") {
      const extendEntering = types[prev] === "round";
      const neighbour = radius(types[extendEntering ? prev : next]);
      const edge = (extendEntering ? enter : leave).x !== 0 ? w : h;
      const k = Math.max(0, Math.min(r * EAR_REACH, edge - r - neighbour));
      const q = earCubic(
        x,
        y,
        r,
        k,
        r * EAR_PULL,
        enter,
        leave,
        extendEntering,
      );
      return {
        start: pt(q.startX, q.startY),
        end: pt(q.endX, q.endY),
        curve: `C ${pt(q.c1x, q.c1y)} ${pt(q.c2x, q.c2y)} ${
          pt(q.endX, q.endY)
        }`,
      };
    }
    const start = pt(x - enter.x * r, y - enter.y * r);
    const end = pt(x + leave.x * r, y + leave.y * r);
    return {
      start,
      end,
      curve: r > 0 ? `A ${num(r)} ${num(r)} 0 0 1 ${end}` : null,
    };
  });
  const [tl, ...rest] = [parts[0], parts[1], parts[2], parts[3]];
  const segs = [...rest, tl].flatMap((p) => [`L ${p.start}`, p.curve]);
  return ["M " + tl.end, ...segs.filter(Boolean), "Z"].join(" ");
}

/** Top ears concave, bottom corners convex. */
export function notchPath(w, h, er, cr) {
  return buildPath(w, h, er, cr, {
    topLeft: "ear",
    topRight: "ear",
    bottomRight: "round",
    bottomLeft: "round",
  });
}

/** Anchor square, its two neighbours ears, the opposite corner round. */
export function cornerPath(w, h, anchor, er, cr) {
  if (!ADJACENT[anchor]) return null;
  const types = Object.fromEntries(
    ORDER.map((n) => [
      n,
      n === anchor ? "square" : ADJACENT[anchor].includes(n) ? "ear" : "round",
    ]),
  );
  return buildPath(w, h, er, cr, types);
}
