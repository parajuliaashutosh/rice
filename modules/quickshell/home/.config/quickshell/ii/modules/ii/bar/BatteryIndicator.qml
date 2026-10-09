import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts

// Samsung One UI style: "85%" then an upright battery that is solid where charged and dim where empty,
// with a bolt cut into it while charging.
MouseArea {
    id: root
    property color colText: Appearance.colors.colOnLayer1
    property color colCutout: Appearance.colors.colLayer0Base // solid bar background, so the bolt reads as a cut-out
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    readonly property color colFill: (isLow && !isCharging) ? Appearance.colors.colError : root.colText
    readonly property color colEmpty: ColorUtils.transparentize(root.colFill, 0.7)

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: (root.isLow && !root.isCharging) ? Appearance.colors.colError : root.colText
            text: `${Math.round(root.percentage * 100)}%`
        }

        Item { // Battery glyph
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 10
            implicitHeight: 18

            Rectangle { // Nub
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 4
                height: 2
                topLeftRadius: 1
                topRightRadius: 1
                color: root.percentage >= 0.995 ? root.colFill : root.colEmpty
            }

            Rectangle { // Body: empty part
                id: body
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height - 2 // nub sits flush on top
                radius: 2.5
                color: root.colEmpty
                clip: true

                Rectangle { // Charged part, rising from the bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: body.height * Math.min(1, root.percentage)
                    radius: 2.5
                    color: root.colFill

                    Behavior on height {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }

                MaterialSymbol { // Charging bolt cut-out
                    visible: root.isCharging
                    anchors.centerIn: parent
                    fill: 1
                    text: "bolt"
                    iconSize: 13
                    color: root.colCutout
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
