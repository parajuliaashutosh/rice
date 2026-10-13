import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    component Dot: StyledText {
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnLayer1
        text: "•"
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 6

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: Qt.locale().toString(DateTime.clock.date, "h:mm AP")
        }

        Dot { visible: root.showDate }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Qt.locale().toString(DateTime.clock.date, "ddd, yyyy MMM dd").toUpperCase()
        }

        Dot { visible: root.showDate && NepaliDate.text !== "" }

        StyledText {
            visible: root.showDate && NepaliDate.text !== ""
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: NepaliDate.text
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow
        cursorShape: Qt.PointingHandCursor
        onClicked: Qt.openUrlExternally("https://www.hamropatro.com")

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
