import Quickshell
import "components"
import "notches/center"
import "notches/controlcenter"
import "notches/osd"
import "notches/workspaces"
import "config"

// One Scope per monitor: spacer plus the top-row surfaces. The centre notch
// (slot c) arrives in the next change.
Scope {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            SpacerSurface {
                screen: perScreen.modelData
            }

            CenterSurface {
                screen: perScreen.modelData
            }

            WorkspacesSurface {
                screen: perScreen.modelData
            }

            OsdSurface {
                screen: perScreen.modelData
                slotName: "bl"
                kind: "brightness"
                mirrored: true
            }

            OsdSurface {
                screen: perScreen.modelData
                slotName: "vr"
                kind: "volume"
            }

            ControlCenterSurface {
                screen: perScreen.modelData
            }
        }
    }
}
