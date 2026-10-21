pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import "../config"
import "../logic/media.mjs" as MediaLogic

// The active media player. Selection is a binding over each player's
// `playbackState`, so it follows play/pause/quit events without polling.
Singleton {
    id: root

    function pick(): var {
        const list = Mpris.players.values;
        const entries = [];
        for (let i = 0; i < list.length; i++) {
            entries.push({
                id: i,
                state: list[i].playbackState === MprisPlaybackState.Playing ? "playing" : "other"
            });
        }
        const id = MediaLogic.selectPlayer(entries);
        return id === null ? null : list[id];
    }

    readonly property var player: pick()
    readonly property bool hasPlayer: player !== null
    readonly property bool playing: player ? player.isPlaying : false
    readonly property bool canPrev: player ? player.canGoPrevious : false
    readonly property bool canNext: player ? player.canGoNext : false
    readonly property string artUrl: player ? (player.trackArtUrl ?? "") : ""

    readonly property var text: MediaLogic.trackText({
        title: player ? player.trackTitle : "",
        album: player ? player.trackAlbum : "",
        artist: player ? player.trackArtist : ""
    }, {
        title: Strings.unknownTitle,
        album: Strings.unknownAlbum,
        artist: Strings.unknownArtist
    })
    readonly property string title: text.title
    readonly property string album: text.album
    readonly property string artist: text.artist

    function togglePlay() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }

    function next() {
        if (player && player.canGoNext)
            player.next();
    }

    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }
}
