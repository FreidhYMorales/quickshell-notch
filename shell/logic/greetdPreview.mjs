// Simulation only: no greeter socket, credentials, or session launch.
export function transition(state, event) {
  if (state === "form" && event === "submit") return "authenticating";
  if (state === "authenticating" && event === "success") return "animating";
  if (state === "authenticating" && event === "failure") return "rejecting";
  if (state === "rejecting" && event === "finished") return "shaking";
  if (state === "shaking" && event === "finished") return "error";
  if (state === "animating" && event === "finished") return "launched";
  if (state === "launched" && event === "reset") return "form";
  if (state === "error" && event === "edit") return "form";
  return state;
}
