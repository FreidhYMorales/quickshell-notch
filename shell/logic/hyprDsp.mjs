// Pure builder for the Lua expression sent to `hyprctl dispatch`.
// Names are validated and every argument is rendered as a Lua literal, so
// no caller-supplied text can break out of the call.

const NAME = /^[a-z_]+(\.[a-z_]+)*$/;
const KEY = /^[A-Za-z_][A-Za-z0-9_]*$/;
const MAX_DEPTH = 3;
const NAMED_ESCAPES = {
  "\\": "\\\\",
  '"': '\\"',
  "\n": "\\n",
  "\r": "\\r",
};

function luaString(text) {
  let body = "";
  for (const ch of text) {
    const code = ch.charCodeAt(0);
    body += NAMED_ESCAPES[ch] ??
      (code < 0x20 || code === 0x7f
        ? `\\${code.toString().padStart(3, "0")}`
        : ch);
  }
  return `"${body}"`;
}

// Lua literal for one value, or null when the value is not representable.
function luaValue(value, depth) {
  switch (typeof value) {
    case "string":
      return luaString(value);
    case "boolean":
      return String(value);
    case "number":
      return Number.isFinite(value) ? String(value) : null;
    case "object":
      return value !== null && !Array.isArray(value)
        ? luaTable(value, depth)
        : null;
    default:
      return null;
  }
}

function luaTable(table, depth) {
  if (depth >= MAX_DEPTH) {
    return null;
  }
  const parts = [];
  for (const [key, value] of Object.entries(table)) {
    const lua = KEY.test(key) ? luaValue(value, depth + 1) : null;
    if (lua === null) {
      return null;
    }
    parts.push(`${key}=${lua}`);
  }
  return `{${parts.join(", ")}}`;
}

/** dspExpr(name, args = []) -> "hl.dsp.<name>(<args>)" | null */
export function dspExpr(name, args = []) {
  if (typeof name !== "string" || !NAME.test(name)) {
    return null;
  }
  if (!Array.isArray(args)) {
    return null;
  }
  const lua = args.map((arg) => luaValue(arg, 0));
  if (lua.includes(null)) {
    return null;
  }
  return `hl.dsp.${name}(${lua.join(", ")})`;
}

/**
 * dpmsExpr(on) -> "hl.dsp.dpms({action=\"enable\"|\"disable\"})"
 *
 * Hyprland 0.57 treats `hl.dsp.dpms("on")` as a toggle: it ignores the string
 * and flips the output, so asking twice turns the panel back off. The table
 * form names the state and is idempotent, which the idle stages require.
 */
export function dpmsExpr(on) {
  return dspExpr("dpms", [
    {
      action: on ? "enable" : "disable",
    },
  ]);
}
