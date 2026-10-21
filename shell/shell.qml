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
                label: Strings.brightness
            }

            OsdSurface {
                screen: perScreen.modelData
                slotName: "vr"
                label: Strings.volume
            }

            ControlCenterSurface {
                screen: perScreen.modelData
            }
        }
    }
}
