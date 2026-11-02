// Pure power menu model: which actions exist, in display order, and which
// end the session and therefore need a hold to confirm.

export const ACTIONS = ["lock", "suspend", "logout", "reboot", "poweroff"];

const HOLD = ["logout", "reboot", "poweroff"];

export function needsHold(action) {
  return HOLD.includes(action);
}
