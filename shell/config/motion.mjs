// Animation tokens shared by the shell (`Timings.qml`) and the greetd login
// surface. They live here instead of `Timings.qml` because the greeter is a
// separate Quickshell entrypoint that cannot import the shell's singletons;
// this module is plain data and loads on the same engine.
//
// Keep these in sync with the shell's motion language: the login surface is
// the same notch, so its morph uses the slow token and the same easing.

export const animFast = 120;
export const animNormal = 220;
export const animSlow = 400;
export const blink = 700;

// greetd login surface.
export const loginMorph = animSlow;
export const loginPulse = blink;
export const loginHover = animFast;
export const loginShake = 60;
export const loginShakeWide = 120;
export const loginReset = 1100;
export const loginAuthTimeout = 20000;
export const loginSimulatedAuth = 650;
export const clockTick = 1000;
