// Pure power menu model: which actions exist, in display order, and which
// end the session and therefore need a hold to confirm.

export const ACTIONS = ["lock", "suspend", "logout", "reboot", "poweroff"];

const HOLD = ["logout", "reboot", "poweroff"];

export function needsHold(action) {
  return HOLD.includes(action);
}

// Argv arrays (no shell). Logout uses the hl.dsp bridge: plain dispatchers do
// not work on this Hyprland build. Lock is a request to the Session contract.
const COMMANDS = {
  lock: { lock: true },
  suspend: { argv: ["systemctl", "suspend-then-hibernate"] },
  logout: { argv: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
  reboot: { argv: ["systemctl", "reboot"] },
  poweroff: { argv: ["systemctl", "poweroff"] },
};

export function commandFor(action) {
  return COMMANDS[action] ?? null;
}

// Nerd Font icons draw wider than their monospace advance, so Qt's centring
// (by advance) pushes them right. The x shift that centres the ink instead.
export function inkCentreOffset({ advance, inkX, inkWidth }) {
  // `+ 0` turns -0 into 0.
  return advance / 2 - (inkX + inkWidth / 2) + 0;
}
