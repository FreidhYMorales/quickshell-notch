import QtQuick
import "../config"

// Token-driven animation: `Behavior on x { Anim {} }`.
NumberAnimation {
    duration: Timings.animNormal
    easing.type: Easing.OutCubic
}
