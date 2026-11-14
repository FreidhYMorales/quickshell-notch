// The launcher's webapp form: what the install helper may be given.
//
// The helper builds the desktop file path out of the name, so the name may not
// carry a separator or hide itself with a leading dot; the URL has to be one a
// browser opens, and a bare host grows an https scheme like the old shell did.

const SEPARATOR = /[/\\]/;
function hasControl(value) {
  for (let i = 0; i < value.length; i++) {
    const code = value.charCodeAt(i);
    if (code < 32 || (code >= 127 && code <= 159)) return true;
  }
  return false;
}
// A scheme as URLs spell it: letter, then letters, digits, `+`, `.` or `-`.
const SCHEME = /^[a-zA-Z][a-zA-Z0-9+.-]*:/;
const HTTP = /^https?:\/\/[^\s/]+/i;

// Returns `{ error, name, url }`: `error` is "" when the pair may be installed,
// otherwise the field at fault, and `url` is the value the helper should get.
export function validateInstall(name, url) {
  const cleanName = String(name ?? "").trim();
  const cleanUrl = String(url ?? "").trim();
  if (cleanName === "") {
    return { error: "nameMissing", name: cleanName, url: cleanUrl };
  }
  if (
    cleanName.startsWith(".") || SEPARATOR.test(cleanName) ||
    hasControl(cleanName)
  ) {
    return { error: "nameUnsafe", name: cleanName, url: cleanUrl };
  }
  if (cleanUrl === "") {
    return { error: "urlMissing", name: cleanName, url: cleanUrl };
  }
  const full = SCHEME.test(cleanUrl) ? cleanUrl : "https://" + cleanUrl;
  if (/\s/.test(full) || hasControl(full) || !HTTP.test(full)) {
    return { error: "urlInvalid", name: cleanName, url: cleanUrl };
  }
  return { error: "", name: cleanName, url: full };
}
