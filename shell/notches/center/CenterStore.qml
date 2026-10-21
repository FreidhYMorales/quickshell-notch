pragma Singleton

import Quickshell
import QtQuick
import "../../services"
import "../../logic/sideLayer.mjs" as SideLayer
import "../../logic/centerState.mjs" as CenterState
import "../../logic/centerView.mjs" as CenterView

// The one global holder of the centre reducer state. Surfaces send events with
// `dispatch` and read `viewFor(screenName)`; effects are executed here.
// Other event sources (notifications, launcher, polkit) arrive in later phases.
Singleton {
    id: root

    property var state: CenterState.initialState(screenNames())

    // What the idle notch shows in its side slots: low > media > battery.
    readonly property string sideLayer: SideLayer.sideLayer(Battery.layer, Mpris.playing)

    function screenNames(): var {
        const names = [];
        for (let i = 0; i < Quickshell.screens.length; i++)
            names.push(Quickshell.screens[i].name);
        return names;
    }

    function viewFor(name: string): var {
        return CenterView.viewFor(state, name);
    }

    function dispatch(event) {
        const result = CenterState.reduce(state, event);
        state = result.state;
        for (let i = 0; i < result.effects.length; i++)
            run(result.effects[i]);
    }

    // Effects whose services do not exist yet are logged only.
    function run(effect) {
        console.log("CenterStore: effect (no service yet): " + JSON.stringify(effect));
    }

    // cava runs only while the media layer shows.
    Binding {
        target: Cava
        property: "wanted"
        value: root.sideLayer === "media"
    }

    Connections {
        function onScreensChanged() {
            root.dispatch({
                type: "ScreensChanged",
                names: root.screenNames()
            });
        }

        target: Quickshell
    }

    Connections {
        function onLockedChanged() {
            root.dispatch({
                type: "Locked",
                on: Session.locked
            });
        }

        target: Session
    }

    // The critical-battery toast arrives with notch-notifications; log until then.
    Connections {
        function onCriticalReached() {
            console.log("CenterStore: battery critical (" + Battery.percentage + "%)");
        }

        target: Battery
    }
}
