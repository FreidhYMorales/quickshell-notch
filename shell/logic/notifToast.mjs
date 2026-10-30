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

// A path or URL loads as is (a picture); a bare (or image://icon/) name goes
// through the theme `lookup`, which returns "" for a missing icon.
const NONE = { source: "", themed: false };
const themed = (path) => (path === "" ? NONE : { source: path, themed: true });

const resolve = (source, lookup) => {
  if (source === "") return NONE;
  if (source.startsWith(THEME_PREFIX)) {
    return themed(lookup(source.slice(THEME_PREFIX.length)));
  }
  if (source.includes("/") || source.includes(":")) {
    return { source, themed: false };
  }
  return themed(lookup(source));
};

// The notification's image wins, then its app icon. `themed` marks theme
// icons (tinted to the accent); pictures keep their colours. An empty source
// means "show the fallback glyph" (Qt would otherwise draw its missing-icon
// checkerboard).
export function toastIconInfo({ image, appIcon }, lookup) {
  const fromImage = resolve(image, lookup);
  return fromImage.source !== "" ? fromImage : resolve(appIcon, lookup);
}

export function toastIcon(notif, lookup) {
  return toastIconInfo(notif, lookup).source;
}
