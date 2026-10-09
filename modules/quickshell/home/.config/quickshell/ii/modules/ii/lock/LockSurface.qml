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

// Lock screen: sharp wallpaper with one frosted-glass card in the middle —
// avatar, name, time, English + Nepali date, password — and quiet power controls below.
MouseArea {
    id: root
    required property LockContext context
    property bool active: false
    readonly property bool requirePasswordToPower: Config.options.lock.security.requirePasswordToPower

    // Smoked glass: dark enough for white text on bright wallpapers, light enough to stay airy on dark ones
    readonly property color colGlass: Qt.rgba(0.08, 0.08, 0.1, 0.28)
    readonly property color colGlassStroke: Qt.rgba(1, 1, 1, 0.18)
    readonly property color colField: Qt.rgba(1, 1, 1, 0.12)
    readonly property color colText: "#ffffff"
    readonly property color colTextDim: Qt.rgba(1, 1, 1, 0.72)
    readonly property string fontMain: Appearance.font.family.main

    property string fullName: ""
    readonly property string displayName: fullName.length > 0 ? fullName : SystemInfo.username

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
            duration: 450
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
        color: "#101014"
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Config.options.background.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: root.width
        sourceSize.height: root.height
    }

    // Soft vignette so white text holds up on any wallpaper
    RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.05) }
            GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.35) }
        }
    }

    // ── Glass card ───────────────────────────────────────────────────────────
    Item {
        id: card
        width: 340
        height: cardColumn.implicitHeight + 72
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 12 * (1 - root.shown)
        opacity: root.shown
        scale: 0.97 + 0.03 * root.shown

        ShaderEffectSource {
            id: cardBackdrop
            anchors.fill: parent
            sourceItem: wallpaper
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            visible: false
        }

        FastBlur {
            id: cardBlur
            anchors.fill: parent
            source: cardBackdrop
            radius: 64
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: cardBlur
            maskSource: Rectangle {
                width: card.width
                height: card.height
                radius: 28
            }
        }

        Rectangle { // Tint + hairline edge
            anchors.fill: parent
            radius: 28
            color: root.colGlass
            border.width: 1
            border.color: root.colGlassStroke
        }

        ColumnLayout {
            id: cardColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 28
                topMargin: 36
            }
            spacing: 0

            // Avatar: ~/.face if present, otherwise the first letter of the name
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 76
                implicitHeight: 76

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.18)
                    border.width: 1
                    border.color: root.colGlassStroke
                    visible: avatar.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: root.displayName.charAt(0).toUpperCase()
                        color: root.colText
                        font.family: root.fontMain
                        font.pixelSize: 32
                        font.weight: Font.DemiBold
                    }
                }

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: `${Directories.home}/.face`
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(152, 152)
                    visible: false
                }
                OpacityMask {
                    anchors.fill: parent
                    visible: avatar.status === Image.Ready
                    source: avatar
                    maskSource: Rectangle {
                        width: 76
                        height: 76
                        radius: 38
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                text: root.displayName
                color: root.colText
                font.family: root.fontMain
                font.pixelSize: 17
                font.weight: Font.Medium
            }

            // Time
            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 22
                spacing: 6

                Text {
                    id: timeText
                    text: Qt.locale().toString(DateTime.clock.date, "h:mm AP").split(" ")[0]
                    color: root.colText
                    font.family: root.fontMain
                    font.pixelSize: 72
                    font.weight: Font.DemiBold
                    font.letterSpacing: -1.5
                }
                Text {
                    anchors.baseline: timeText.baseline
                    text: Qt.locale().toString(DateTime.clock.date, "AP")
                    color: root.colTextDim
                    font.family: root.fontMain
                    font.pixelSize: 18
                    font.weight: Font.Medium
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                text: Qt.locale().toString(DateTime.clock.date, "dddd, MMMM d")
                color: root.colText
                font.family: root.fontMain
                font.pixelSize: 15
                font.weight: Font.Medium
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                visible: NepaliDate.longText !== ""
                text: NepaliDate.longText
                color: root.colTextDim
                font.pixelSize: 14
            }

            // Password
            Rectangle {
                id: field
                Layout.fillWidth: true
                Layout.topMargin: 30
                implicitHeight: 44
                radius: height / 2
                color: root.colField
                border.width: 1
                border.color: GlobalStates.screenUnlockFailed ? Qt.rgba(1, 0.45, 0.45, 0.7) : (passwordBox.activeFocus ? Qt.rgba(1, 1, 1, 0.35) : root.colGlassStroke)

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
                    fill: 1
                    text: root.context.fingerprintsConfigured ? "fingerprint" : "lock"
                    iconSize: 18
                    color: root.colTextDim
                }

                TextField {
                    id: passwordBox
                    anchors {
                        left: lockIcon.right
                        right: submit.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 6
                        rightMargin: 6
                    }
                    background: null
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: root.colText
                    font.family: root.fontMain
                    font.pixelSize: text.length > 0 ? 18 : 14
                    font.letterSpacing: text.length > 0 ? 2 : 0
                    placeholderText: GlobalStates.screenUnlockFailed ? Translation.tr("Incorrect password") : Translation.tr("Enter password")
                    placeholderTextColor: GlobalStates.screenUnlockFailed ? "#ffb4ab" : root.colTextDim
                    selectionColor: Qt.rgba(1, 1, 1, 0.25)
                    echoMode: TextInput.Password
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

                Rectangle { // Submit
                    id: submit
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    radius: 17
                    color: submitArea.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, root.context.currentText.length > 0 ? 0.24 : 0.12)
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            if (root.context.unlockInProgress)
                                return "progress_activity";
                            if (root.context.targetAction === LockContext.ActionEnum.Poweroff)
                                return "power_settings_new";
                            if (root.context.targetAction === LockContext.ActionEnum.Reboot)
                                return "restart_alt";
                            return root.ctrlHeld ? "coffee" : "arrow_forward";
                        }
                        iconSize: 18
                        color: root.colText
                    }
                    MouseArea {
                        id: submitArea
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

    // ── Bottom: battery + power controls ─────────────────────────────────────
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        spacing: 10
        opacity: root.shown

        Rectangle { // Battery
            visible: Battery.available
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            width: batteryRow.implicitWidth + 28
            radius: 20
            color: root.colGlass
            border.width: 1
            border.color: root.colGlassStroke

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    fill: 1
                    text: Battery.isCharging ? "battery_charging_full" : "battery_android_full"
                    iconSize: 18
                    color: (Battery.isLow && !Battery.isCharging) ? "#ffb4ab" : root.colText
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `${Math.round(Battery.percentage * 100)}%`
                    color: root.colText
                    font.family: root.fontMain
                    font.pixelSize: 13
                }
            }
        }

        GlassButton {
            icon: "dark_mode"
            onClicked: Session.suspend()
        }
        GuardedGlassButton {
            icon: "restart_alt"
            targetAction: LockContext.ActionEnum.Reboot
        }
        GuardedGlassButton {
            icon: "power_settings_new"
            targetAction: LockContext.ActionEnum.Poweroff
        }
    }

    component GlassButton: Rectangle {
        id: btn
        required property string icon
        property bool toggled: false
        signal clicked

        width: 40
        height: 40
        radius: 20
        color: toggled ? Qt.rgba(1, 1, 1, 0.32) : (btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : root.colGlass)
        border.width: 1
        border.color: root.colGlassStroke
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: btn.icon
            iconSize: 20
            color: root.colText
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component GuardedGlassButton: GlassButton {
        id: guarded
        required property var targetAction
        toggled: root.context.targetAction === guarded.targetAction
        onClicked: {
            if (!root.requirePasswordToPower) {
                root.context.unlocked(guarded.targetAction);
                return;
            }
            if (root.context.targetAction === guarded.targetAction) {
                root.context.resetTargetAction();
            } else {
                root.context.targetAction = guarded.targetAction;
                root.context.shouldReFocus();
            }
        }
    }
}
