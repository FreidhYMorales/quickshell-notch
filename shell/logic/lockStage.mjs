// What the lock shows and what an input does while it was locked from
// idleness. Stages: "normal" (the usual lock), "screensaver" (the wallpaper
// alone with the padlock notch) and "black" (nothing: the OLED is off).

export function lockLooks(stage) {
  return {
    wallpaper: stage !== "black",
    content: stage === "normal",
    notch: stage !== "black",
  };
}

// Any input in the screensaver or black stage leaves it for the lock form;
// the black stage paints one black frame first so nothing flashes. In the
// normal lock the input keeps its usual meaning.
export function inputEnds(stage) {
  return { stage: "normal", blackFrame: stage === "black" };
}

// The black stage only darkens a session that is already locked; without a
// lock it asks for the usual one (screensaver minutes at zero).
export function idleStageAction(locked) {
  return locked ? "black" : "lock";
}

// A surface that has just gained pointer focus reports the pointer's resting
// position as movement; only a real move past the threshold ends a stage.
export function movedPast(base, point, threshold) {
  const dx = point.x - base.x;
  const dy = point.y - base.y;
  return Math.sqrt(dx * dx + dy * dy) >= threshold;
}

// What each stage asks of the shell and the compositor: the layer painted over
// the lock look (null on the normal lock), whether the pointer is hidden, and
// whether the outputs stay on. The black stage leaves them off (DPMS) with the
// session still locked.
export function stageEffects(stage) {
  return {
    overlay: stage === "normal"
      ? null
      : (stage === "screensaver" ? "wallpaper" : "black"),
    pointerHidden: stage !== "normal",
    outputsOn: stage !== "black",
  };
}

// Whether `hyprctl monitors -j` says every output is back on after the black
// stage turned them off. Anything unreadable counts as awake: the lock must
// never stay black because a monitor failed to report.
export function outputsAwake(json) {
  let monitors;
  try {
    monitors = JSON.parse(json);
  } catch (_e) {
    return true;
  }
  if (!Array.isArray(monitors)) {
    return true;
  }
  for (let i = 0; i < monitors.length; ++i) {
    const monitor = monitors[i];
    if (monitor && monitor.dpmsStatus === false) {
      return false;
    }
  }
  return true;
}
