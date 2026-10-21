// Pure player rules. The service maps MPRIS playback to "playing" and others.

// First playing player, else the first one, else null.
export function selectPlayer(players) {
  for (let i = 0; i < players.length; i++) {
    if (players[i].state === "playing") return players[i].id;
  }
  return players.length > 0 ? players[0].id : null;
}

function textOr(value, fallback) {
  return value && String(value).trim() !== "" ? value : fallback;
}

export function trackText(meta, fallbacks) {
  return {
    title: textOr(meta.title, fallbacks.title),
    album: textOr(meta.album, fallbacks.album),
    artist: textOr(meta.artist, fallbacks.artist),
  };
}
