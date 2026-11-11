// Selectable human accounts parsed from /etc/passwd. The greeter runs before
// any login, so this file is the only user list that is always readable.
const DENIED_SHELL = /(?:^|\/)(?:nologin|false)$/;

function isHuman(uid) {
  return isFinite(uid) && uid >= 1000 && uid < 65534;
}

export function humanUsers(passwdText) {
  const users = [];
  const seen = {};
  for (const line of String(passwdText || "").split(/\r?\n/)) {
    if (!line || line[0] === "#") continue;
    const fields = line.split(":");
    if (fields.length < 7) continue;
    const name = fields[0];
    const uid = Number(fields[2]);
    const gecos = String(fields[4] || "").split(",")[0].trim();
    const shell = fields[6];
    if (!name || !isHuman(uid) || DENIED_SHELL.test(shell)) continue;
    if (seen[uid]) continue;
    seen[uid] = true;
    users.push({ name: name, displayName: gecos || name, uid: uid });
  }
  users.sort((a, b) => a.uid - b.uid);
  return users.map((user) => ({
    name: user.name,
    displayName: user.displayName,
  }));
}

export function defaultUser(users, preferred) {
  const list = users || [];
  for (const user of list) {
    if (user.name === preferred) return user.name;
  }
  return list.length > 0 ? list[0].name : "";
}

// AccountsService caches public login avatars here. A missing or unreadable
// file is handled by the surface's vector fallback, without reading homes.
export function avatarUrl(name) {
  const user = String(name || "");
  if (!/^[a-zA-Z0-9_][a-zA-Z0-9_.-]*\$?$/.test(user)) return "";
  return "file:///var/lib/AccountsService/icons/" + user;
}
