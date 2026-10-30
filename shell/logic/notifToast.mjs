// Pure helpers for the notification toast. No Qt imports, no I/O.

// The DBus "default" action runs on a body click; every other action is a
// button.
export function toastActions(actions) {
  const buttons = [];
  let bodyAction = null;
  for (const action of actions) {
    if (action.identifier === "default") bodyAction = action;
    else buttons.push(action);
  }
  return { buttons, bodyAction };
}

const THEME_PREFIX = "image://icon/";

// A path or URL loads as is; a bare (or image://icon/) name goes through the
// theme `lookup`, which returns "" for a missing icon.
const resolve = (source, lookup) => {
  if (source === "") return "";
  if (source.startsWith(THEME_PREFIX)) {
    return lookup(source.slice(THEME_PREFIX.length));
  }
  if (source.includes("/") || source.includes(":")) return source;
  return lookup(source);
};

// The notification's image wins, then its app icon; "" means "show the
// fallback glyph" (Qt would otherwise draw its missing-icon checkerboard).
export function toastIcon({ image, appIcon }, lookup) {
  return resolve(image, lookup) || resolve(appIcon, lookup);
}
