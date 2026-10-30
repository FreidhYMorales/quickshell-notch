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
