// Pure merge of the battery layer and media playback into the one layer the
// idle notch shows in its side slots. Priority: low > media > battery > none.

/** sideLayer(batteryLayer, playing) -> "low"|"media"|"charging"|"plugged"|"full"|"none" */
export function sideLayer(batteryLayer, playing) {
  if (batteryLayer === "low") return "low";
  if (playing) return "media";
  return batteryLayer;
}

/** sideWidth(layer, { battery, media }) -> 0 | battery | media */
export function sideWidth(layer, sides) {
  if (layer === "none") return 0;
  return layer === "media" ? sides.media : sides.battery;
}
