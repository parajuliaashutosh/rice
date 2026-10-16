pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

// macOS Spaces-style strip: one thumbnail per workspace showing the wallpaper with
// to-scale snapshots of its windows. The current workspace gets a thin ring; the number sits below.
// Width is set by the parent; thumbnails grow to fill it.
Rectangle {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    // Clamp to avoid the lock screen's temporary workspace leaking into the UI
    readonly property int activeWorkspace: Math.max(1, Math.min(100, monitor?.activeWorkspace?.id ?? 1))
    readonly property int count: 10
    readonly property int group: Math.floor((activeWorkspace - 1) / count)
    readonly property string wallpaper: Config.options.background.wallpaperPath

    readonly property real padding: 14
    readonly property real spacing: 12
    readonly property real thumbWidth: Math.floor((width - padding * 2 - spacing * (count - 1)) / count)
    readonly property real thumbHeight: Math.round(thumbWidth * (monitor?.height ?? 9) / (monitor?.width ?? 16))
    // Hyprland gaps_out (5) + border_size (1): trimmed with the bar's reserved space so windows fill the thumbnail
    readonly property real edgeInset: 6

    // Hyprland address -> Wayland toplevel, for the live previews
    readonly property var toplevelByAddress: {
        const map = {};
        for (const t of ToplevelManager.toplevels.values)
            map[`0x${t.HyprlandToplevel?.address}`] = t;
        return map;
    }

    function focusWorkspace(ws) {
        GlobalStates.overviewOpen = false;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws} })`);
    }

    implicitHeight: row.implicitHeight + padding * 2
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: root.count
            delegate: Column {
                id: cell
                required property int index
                readonly property int ws: root.group * root.count + index + 1
                readonly property bool active: ws === root.activeWorkspace
                readonly property var windows: HyprlandData.windowList.filter(w => w.workspace.id === cell.ws && w.mapped && !w.hidden)
                spacing: 7

                Item {
                    width: root.thumbWidth
                    height: root.thumbHeight

                    ClippingRectangle {
                        id: thumb
                        anchors.fill: parent
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1

                        Image {
                            anchors.fill: parent
                            source: root.wallpaper ? `file://${root.wallpaper}` : ""
                            sourceSize.width: root.thumbWidth * 2
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                        }

                        // Windows: snapshots at their real position and size
                        Repeater {
                            model: cell.windows
                            delegate: Item {
                                id: win
                                required property var modelData
                                readonly property var mon: HyprlandData.monitors.find(m => m.id === win.modelData.monitor) ?? root.monitorData
                                // Usable area: monitor minus reserved space (bar) and the outer gap
                                readonly property var res: mon?.reserved ?? [0, 0, 0, 0]
                                readonly property real areaX: (mon?.x ?? 0) + res[0] + root.edgeInset
                                readonly property real areaY: (mon?.y ?? 0) + res[1] + root.edgeInset
                                readonly property real areaW: (mon?.width ?? 1920) / (mon?.scale ?? 1) - res[0] - res[2] - root.edgeInset * 2
                                readonly property real areaH: (mon?.height ?? 1080) / (mon?.scale ?? 1) - res[1] - res[3] - root.edgeInset * 2
                                readonly property real sx: root.thumbWidth / areaW
                                readonly property real sy: root.thumbHeight / areaH
                                x: (modelData.at[0] - areaX) * sx
                                y: (modelData.at[1] - areaY) * sy
                                z: modelData.floating ? 1 : 0
                                width: Math.max(2, modelData.size[0] * sx)
                                height: Math.max(2, modelData.size[1] * sy)

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: GlobalStates.overviewOpen ? (root.toplevelByAddress[win.modelData.address] ?? null) : null
                                    // One snapshot per open: streaming every window each frame made the launcher lag
                                    live: false
                                }
                            }
                        }
                    }

                    Rectangle { // Ring: current workspace (solid) or hover (faint), around the thumbnail only
                        anchors {
                            fill: parent
                            margins: -border.width // flush with the thumbnail, no gap
                        }
                        radius: thumb.radius + border.width
                        color: "transparent"
                        border.width: 2
                        border.color: cell.active ? Appearance.colors.colOnLayer0 : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.7)
                        visible: cell.active || cellMouse.containsMouse
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWorkspace(cell.ws)
                    }
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.ws
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: cell.active ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                }
            }
        }
    }
}
