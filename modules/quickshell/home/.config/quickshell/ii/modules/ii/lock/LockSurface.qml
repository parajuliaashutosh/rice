import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.panels.lock
import Quickshell
import Quickshell.Io

// Editorial lock screen: wallpaper on the right, a quiet left column with a serif clock,
// English + Nepali date and a small sign-in card; weather top-right, power bottom-right.
MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

    // Palette
    readonly property color colText: "#f3efe8"
    readonly property color colDim: Qt.rgba(0.95, 0.94, 0.91, 0.62)
    readonly property color colFaint: Qt.rgba(1, 1, 1, 0.14)
    readonly property color colAccent: "#c9a77c"
    readonly property color colError: "#e8a39a"
    readonly property string fontSerif: "Noto Serif"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: Appearance.font.family.main

    property string fullName: ""
    readonly property string displayName: fullName.length > 0 ? fullName : SystemInfo.username

    function weatherText(code) {
        const c = Number(code);
        if (c === 113) return "Clear skies";
        if (c === 116) return "Partly cloudy";
        if (c === 119 || c === 122) return "Overcast";
        if ([143, 248, 260].includes(c)) return "Misty";
        if ([200, 386, 389, 392, 395].includes(c)) return "Thunderstorms";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].includes(c)) return "Snow";
        if ([182, 185, 281, 284, 311, 314, 317, 320, 350, 362, 365, 374, 377].includes(c)) return "Sleet";
        if ([176, 263, 266, 293, 296, 353].includes(c)) return "Light rain";
        if ([299, 302, 305, 308, 356, 359].includes(c)) return "Rain";
        return "";
    }

    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: root.context
        function onShouldReFocus() {
            root.forceFieldFocus();
        }
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: forceFieldFocus()
    onPositionChanged: forceFieldFocus()

    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = true;
        if (event.key === Qt.Key_Escape)
            root.context.currentText = "";
        forceFieldFocus();
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control)
            root.ctrlHeld = false;
        forceFieldFocus();
    }

    Process {
        running: true
        command: ["bash", "-c", "getent passwd \"$USER\" | cut -d: -f5"]
        stdout: SplitParser {
            onRead: data => root.fullName = data.split(",")[0].trim()
        }
    }

    // Entrance
    property real shown: 0
    Behavior on shown {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }
    Component.onCompleted: {
        forceFieldFocus();
        shown = 1;
    }

    // ── Wallpaper ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "#0c0c0e"
    }

    Image {
        anchors.fill: parent
        source: Config.options.background.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    Rectangle { // Overall dim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.28)
    }

    LinearGradient { // Darker on the left, where the text lives
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(root.width * 0.62, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.62) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
        }
    }

    // ── Building blocks ──────────────────────────────────────────────────────
    component Label: Text {
        color: root.colText
        font.family: root.fontMono
        font.pixelSize: 12
        font.letterSpacing: 4
        font.capitalization: Font.AllUppercase
    }

    component Rule: Rectangle {
        implicitWidth: 22
        implicitHeight: 1.5
        color: root.colAccent
    }

    // ── Top left: motto ──────────────────────────────────────────────────────
    Column {
        anchors {
            left: parent.left
            top: parent.top
            margins: 64
        }
        spacing: 6
        opacity: root.shown

        Label {
            text: "Good things"
            font.pixelSize: 14
            font.letterSpacing: 5
        }
        Label {
            text: "Take time"
            color: root.colDim
            font.pixelSize: 10
        }
        Rule {
            anchors.left: parent.left
        }
    }

    // ── Top right: weather ───────────────────────────────────────────────────
    Column {
        visible: Config.options.bar.weather.enable
        anchors {
            right: parent.right
            top: parent.top
            margins: 64
        }
        spacing: 8
        opacity: root.shown

        Row {
            anchors.right: parent.right
            spacing: 10
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: 22
                color: root.colText
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.data?.temp ?? "--°"
                font.pixelSize: 15
                font.letterSpacing: 3
            }
        }
        Label {
            anchors.right: parent.right
            text: Weather.data?.city ?? ""
            font.capitalization: Font.MixedCase
        }
        Rule {
            anchors.right: parent.right
        }
        Label {
            anchors.right: parent.right
            text: root.weatherText(Weather.data.wCode)
            color: root.colDim
            font.pixelSize: 10
        }
    }

    // ── Left column: clock, dates, sign-in ───────────────────────────────────
    ColumnLayout {
        id: leftColumn
        anchors {
            left: parent.left
            leftMargin: Math.max(96, root.width * 0.11) - 16 * (1 - root.shown)
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: 10
        }
        spacing: 0
        opacity: root.shown

        Row {
            spacing: 10
            Text {
                id: clockText
                text: Qt.locale().toString(DateTime.clock.date, "hh:mm AP").split(" ")[0]
                color: root.colText
                font.family: root.fontSerif
                font.pixelSize: 132
                font.weight: Font.Light
                font.letterSpacing: -2
            }
            Label {
                anchors.baseline: clockText.baseline
                text: Qt.locale().toString(DateTime.clock.date, "AP")
                color: root.colDim
                font.pixelSize: 14
            }
        }

        Label {
            Layout.topMargin: 4
            text: Qt.locale().toString(DateTime.clock.date, "ddd, MMM dd, yyyy")
            font.pixelSize: 22
            font.letterSpacing: 6
        }

        Text {
            Layout.topMargin: 10
            visible: NepaliDate.text !== ""
            text: NepaliDate.text
            color: root.colDim
            font.family: "Noto Sans Devanagari"
            font.pixelSize: 17
            font.letterSpacing: 1
        }

        Rule {
            Layout.topMargin: 22
        }

        // Sign-in card; the avatar sits on its top edge
        Item {
            Layout.topMargin: 64
            implicitWidth: 320
            implicitHeight: card.height

            Rectangle {
                id: card
                width: parent.width
                height: cardColumn.implicitHeight + 64
                radius: 18
                color: Qt.rgba(0.04, 0.04, 0.05, 0.55)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Avatar: ~/.face if present, otherwise a person glyph, in a thin accent ring
            Rectangle {
                id: avatarRing
                anchors.horizontalCenter: card.horizontalCenter
                anchors.verticalCenter: card.top
                width: 60
                height: 60
                radius: 30
                color: "#141416"
                border.width: 1
                border.color: root.colAccent

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: avatar.status !== Image.Ready
                    text: "person"
                    iconSize: 28
                    color: root.colText
                }
                Image {
                    id: avatar
                    anchors.fill: parent
                    anchors.margins: 3
                    source: `${Directories.home}/.face`
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(120, 120)
                    visible: false
                }
                OpacityMask {
                    anchors.fill: avatar
                    visible: avatar.status === Image.Ready
                    source: avatar
                    maskSource: Rectangle {
                        width: avatar.width
                        height: avatar.height
                        radius: width / 2
                    }
                }
            }

            ColumnLayout {
                id: cardColumn
                anchors {
                    left: card.left
                    right: card.right
                    top: card.top
                    margins: 22
                    topMargin: 42
                }
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.displayName
                    color: root.colText
                    font.family: root.fontSans
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    visible: root.fullName.length > 0
                    text: SystemInfo.username
                    color: root.colDim
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    font.capitalization: Font.MixedCase
                }

                // Password
                Rectangle {
                    id: field
                    Layout.fillWidth: true
                    Layout.topMargin: 22
                    implicitHeight: 42
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: GlobalStates.screenUnlockFailed ? root.colError : (passwordBox.activeFocus ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.16))
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    transform: Translate {
                        id: shake
                    }
                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 10; duration: 60 }
                        NumberAnimation { target: shake; property: "x"; to: -6; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 4; duration: 50 }
                        NumberAnimation { target: shake; property: "x"; to: 0; duration: 40 }
                    }
                    Connections {
                        target: GlobalStates
                        function onScreenUnlockFailedChanged() {
                            if (GlobalStates.screenUnlockFailed)
                                shakeAnim.restart();
                        }
                    }

                    MaterialSymbol {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.context.fingerprintsConfigured ? "fingerprint" : "lock"
                        iconSize: 17
                        color: root.colDim
                    }

                    TextField {
                        id: passwordBox
                        property bool reveal: false
                        anchors {
                            left: lockIcon.right
                            right: eye.left
                            top: parent.top
                            bottom: parent.bottom
                            leftMargin: 8
                            rightMargin: 4
                        }
                        background: null
                        verticalAlignment: Text.AlignVCenter
                        color: root.colText
                        font.family: root.fontSans
                        font.pixelSize: 14
                        placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter your password")
                        placeholderTextColor: GlobalStates.screenUnlockFailed ? root.colError : root.colDim
                        selectionColor: Qt.rgba(0.79, 0.65, 0.49, 0.4)
                        echoMode: reveal ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        inputMethodHints: Qt.ImhSensitiveData
                        enabled: !root.context.unlockInProgress

                        onTextChanged: root.context.currentText = this.text
                        onAccepted: root.context.tryUnlock(root.ctrlHeld)
                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                passwordBox.text = root.context.currentText;
                            }
                        }
                        Keys.onPressed: event => root.context.resetClearTimer()
                    }

                    MaterialSymbol {
                        id: eye
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: passwordBox.reveal ? "visibility_off" : "visibility"
                        iconSize: 17
                        color: eyeArea.containsMouse ? root.colText : root.colDim
                        MouseArea {
                            id: eyeArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                passwordBox.reveal = !passwordBox.reveal;
                                root.forceFieldFocus();
                            }
                        }
                    }
                }

                // Sign in
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    implicitHeight: 42
                    radius: height / 2
                    color: signInArea.containsMouse ? Qt.rgba(0.79, 0.65, 0.49, 0.14) : "transparent"
                    border.width: 1
                    border.color: root.colAccent
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: {
                            if (root.context.unlockInProgress)
                                return "Signing in";
                            if (root.context.targetAction === LockContext.ActionEnum.Poweroff)
                                return "Power off";
                            if (root.context.targetAction === LockContext.ActionEnum.Reboot)
                                return "Restart";
                            return "Sign in";
                        }
                        font.pixelSize: 11
                        font.capitalization: Font.MixedCase
                    }
                    MaterialSymbol {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.ctrlHeld ? "coffee" : "login"
                        iconSize: 17
                        color: root.colAccent
                    }
                    MouseArea {
                        id: signInArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.context.unlockInProgress
                        onClicked: root.context.tryUnlock(root.ctrlHeld)
                    }
                }
            }
        }
    }

    // ── Bottom left: quote ───────────────────────────────────────────────────
    Column {
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 64
        }
        spacing: 10
        opacity: root.shown

        Label {
            text: "Discipline today,\nfreedom tomorrow."
            color: root.colDim
            font.pixelSize: 11
            font.letterSpacing: 2.5
            font.capitalization: Font.MixedCase
            lineHeight: 1.4
        }
        Rule {}
    }

    // ── Bottom right: battery + power ────────────────────────────────────────
    Row {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 56
        }
        spacing: 0
        opacity: root.shown

        Label {
            visible: Battery.available
            anchors.verticalCenter: parent.verticalCenter
            rightPadding: 18
            text: `${Math.round(Battery.percentage * 100)}%`
            color: (Battery.isLow && !Battery.isCharging) ? root.colError : root.colDim
            font.pixelSize: 11
            font.letterSpacing: 2
        }
        PowerButton {
            icon: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }
        Divider {}
        PowerButton {
            icon: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
        Divider {}
        PowerButton {
            icon: "dark_mode"
            onActivated: Session.suspend()
        }
    }

    component Divider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 16
        color: root.colFaint
    }

    // Power off / restart follow the shell's "require password to power" setting
    component PowerButton: Item {
        id: btn
        required property string icon
        property var targetAction: null
        readonly property bool toggled: targetAction !== null && root.context.targetAction === targetAction
        signal activated

        width: 40
        height: 36

        MaterialSymbol {
            anchors.centerIn: parent
            text: btn.icon
            iconSize: 20
            color: btn.toggled ? root.colAccent : (btnArea.containsMouse ? root.colText : root.colDim)
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (btn.targetAction === null) {
                    btn.activated();
                    return;
                }
                if (!root.requirePasswordToPower) {
                    root.context.unlocked(btn.targetAction);
                    return;
                }
                if (btn.toggled) {
                    root.context.resetTargetAction();
                } else {
                    root.context.targetAction = btn.targetAction;
                    root.context.shouldReFocus();
                }
            }
        }
    }
}
