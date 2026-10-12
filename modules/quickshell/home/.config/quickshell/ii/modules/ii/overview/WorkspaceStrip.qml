pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

// macOS Spaces-style strip: one small wallpaper thumbnail per workspace with its windows
// drawn to scale. The current workspace just gets a thin border; no glow.
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

    readonly property real thumbWidth: 76
    readonly property real thumbHeight: Math.round(thumbWidth * (monitor?.height ?? 9) / (monitor?.width ?? 16))
    readonly property real cellPadding: 5

    // Frosted glass over the blurred backdrop, tinted by the wallpaper palette
    readonly property color colPanel: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.93)
    readonly property color colBorder: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)
    readonly property color colCell: "transparent"
    readonly property color colCellHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.92)

    function focusWorkspace(ws) {
        GlobalStates.overviewOpen = false;
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws} })`);
    }

    // First empty workspace after the ones in use
    function nextEmptyWorkspace() {
        const used = HyprlandData.windowList.map(w => w.workspace.id).filter(id => id > 0);
        for (let ws = 1; ws <= 100; ws++)
            if (!used.includes(ws) && ws !== root.activeWorkspace)
                return ws;
        return root.activeWorkspace;
    }

    implicitWidth: row.implicitWidth + 12
    implicitHeight: row.implicitHeight + 12
    radius: height / 2
    color: colPanel
    border.width: 1
    border.color: colBorder

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.count
            delegate: Rectangle {
                id: cell
                required property int index
                readonly property int ws: root.group * root.count + index + 1
                readonly property bool active: ws === root.activeWorkspace
                readonly property var windows: HyprlandData.windowList.filter(w => w.workspace.id === cell.ws)

                implicitWidth: cellRow.implicitWidth + root.cellPadding * 2
                implicitHeight: root.thumbHeight + root.cellPadding * 2
                radius: Appearance.rounding.small + root.cellPadding
                color: cellMouse.containsMouse ? root.colCellHover : root.colCell
                border.width: active ? 1.5 : 0
                border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.25)
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }

                Row {
                    id: cellRow
                    anchors.centerIn: parent
                    spacing: 7

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 3
                        text: cell.ws
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: cell.active ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                    }

                    ClippingRectangle {
                        width: root.thumbWidth
                        height: root.thumbHeight
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1
                        opacity: cell.active || cellMouse.containsMouse ? 1 : 0.7

                        Image {
                            anchors.fill: parent
                            source: root.wallpaper ? `file://${root.wallpaper}` : ""
                            sourceSize.width: root.thumbWidth * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        // Windows, drawn to scale
                        Repeater {
                            model: cell.windows
                            delegate: Rectangle {
                                id: win
                                required property var modelData
                                readonly property var mon: HyprlandData.monitors.find(m => m.id === win.modelData.monitor) ?? root.monitorData
                                readonly property real sx: root.thumbWidth / ((mon?.width ?? 1920) / (mon?.scale ?? 1))
                                readonly property real sy: root.thumbHeight / ((mon?.height ?? 1080) / (mon?.scale ?? 1))
                                x: (modelData.at[0] - (mon?.x ?? 0)) * sx
                                y: (modelData.at[1] - (mon?.y ?? 0)) * sy
                                width: Math.max(4, modelData.size[0] * sx)
                                height: Math.max(4, modelData.size[1] * sy)
                                radius: 2
                                color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.2)
                                border.width: 0.5
                                border.color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.8)

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: Math.min(14, parent.width - 2, parent.height - 2)
                                    visible: implicitSize >= 6
                                    source: Quickshell.iconPath(AppSearch.guessIcon(win.modelData.class), "image-missing")
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(cell.ws)
                }
            }
        }

        RippleButton { // New workspace
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.thumbHeight + root.cellPadding * 2
            implicitHeight: implicitWidth
            buttonRadius: implicitWidth / 2
            colBackground: root.colCell
            colBackgroundHover: root.colCellHover
            onClicked: root.focusWorkspace(root.nextEmptyWorkspace())
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: "add"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer0
            }
            StyledToolTip {
                text: Translation.tr("New workspace")
            }
        }
    }
}
