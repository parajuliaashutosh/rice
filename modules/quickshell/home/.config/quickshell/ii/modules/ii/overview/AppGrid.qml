pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Launchpad-style app pages shown under the search bar while nothing is typed.
// Page 1 is favourites (pinned apps, then common ones that are installed); the following
// pages hold every app A–Z. Flip pages with the scroll wheel, a swipe or the dots.
Rectangle {
    id: root
    signal searchRequested(string text)

    // As many ~140px columns as fit, so the panel can be as wide as the screen allows
    readonly property int columns: Math.max(6, Math.floor((width - 36) / 140))
    readonly property int rows: 3
    readonly property int perPage: columns * rows
    readonly property real cellHeight: 100

    readonly property color colBorder: Appearance.colors.colLayer0Border
    readonly property color colHover: Appearance.colors.colLayer1Hover

    // Known apps in display order; each slot lists alternative desktop IDs (distro, vendor, Flatpak)
    readonly property var commonApps: [
        ["org.mozilla.firefox", "firefox"],
        ["code", "com.visualstudio.code", "codium"],
        ["kitty", "org.wezfurlong.wezterm", "Alacritty", "foot"],
        ["org.kde.dolphin", "org.gnome.Nautilus", "thunar"],
        ["brave-browser", "com.brave.Browser"],
        ["google-chrome", "com.google.Chrome"],
        ["spotify", "com.spotify.Client"],
        ["discord", "com.discordapp.Discord"],
        ["slack", "com.slack.Slack"],
        ["org.telegram.desktop"],
        ["dev.zed.Zed", "zed"],
        ["obsidian", "md.obsidian.Obsidian"],
        ["jetbrains-idea", "jetbrains-idea-ce", "com.jetbrains.IntelliJ-IDEA-Community"],
        ["nvim"],
        ["dbeaver", "io.dbeaver.DBeaverCommunity"],
        ["org.mozilla.Thunderbird", "thunderbird"],
        ["com.obsproject.Studio"],
        ["libreoffice-writer"],
        ["libreoffice-calc"],
        ["libreoffice-impress"],
        ["org.kde.kcalc", "org.gnome.Calculator"],
        ["org.gnome.Calendar", "org.kde.merkuro.calendar"],
        ["org.gnome.Contacts"],
        ["systemsettings", "org.gnome.Settings"],
        ["org.kde.plasma-systemmonitor", "org.gnome.SystemMonitor", "btop"],
    ]

    readonly property var allApps: AppSearch.list
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var favourites: {
        const byId = {};
        for (const app of root.allApps) byId[app.id] = app;
        const out = [];
        const add = app => { if (app && !out.includes(app)) out.push(app); };
        for (const id of Config.options.launcher.pinnedApps) add(byId[id]);
        for (const slot of root.commonApps) add(slot.map(id => byId[id]).find(Boolean));
        return out.slice(0, root.perPage);
    }

    readonly property var pages: {
        const out = [{ title: Translation.tr("Favourites"), apps: root.favourites }];
        for (let i = 0; i < root.allApps.length; i += root.perPage)
            out.push({ title: Translation.tr("All apps"), apps: root.allApps.slice(i, i + root.perPage) });
        return out;
    }

    function goToPage(i) {
        pageView.currentIndex = Math.max(0, Math.min(pageView.count - 1, i));
    }

    implicitHeight: content.implicitHeight + 36
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer0
    border.width: 1
    border.color: colBorder

    // The panel stays loaded between opens; start on favourites each time
    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) pageView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    ColumnLayout {
        id: content
        anchors {
            fill: parent
            margins: 18
        }
        spacing: 8

        RowLayout { // Header
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            StyledText {
                Layout.fillWidth: true
                text: root.pages[pageView.currentIndex]?.title ?? ""
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
            }
            StyledText {
                visible: pageView.currentIndex > 0
                text: Translation.tr("%1 of %2").arg(pageView.currentIndex).arg(pageView.count - 1)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        ListView { // Pages
            id: pageView
            Layout.fillWidth: true
            implicitHeight: root.rows * root.cellHeight
            orientation: ListView.Horizontal
            snapMode: ListView.SnapOneItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 280
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            model: root.pages

            delegate: Grid {
                id: page
                required property var modelData
                width: pageView.width
                height: pageView.height
                columns: root.columns

                Repeater {
                    model: page.modelData.apps
                    delegate: RippleButton {
                        id: appButton
                        required property var modelData
                        width: pageView.width / root.columns
                        height: root.cellHeight
                        buttonRadius: Appearance.rounding.normal
                        colBackground: "transparent"
                        colBackgroundHover: root.colHover
                        onClicked: {
                            GlobalStates.overviewOpen = false;
                            appButton.modelData.execute();
                        }
                        contentItem: ColumnLayout {
                            anchors.fill: parent
                            anchors.topMargin: 12
                            anchors.bottomMargin: 4
                            spacing: 7
                            IconImage {
                                Layout.alignment: Qt.AlignHCenter
                                implicitSize: 46
                                source: Quickshell.iconPath(appButton.modelData.icon, "application-x-executable")
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignTop
                                text: appButton.modelData.name
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                        StyledToolTip {
                            text: appButton.modelData.comment || appButton.modelData.name
                        }
                    }
                }
            }

            // Mouse wheel / touchpad: one page per notch or swipe
            WheelHandler {
                property real acc: 0
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    const d = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y;
                    acc += d;
                    if (Math.abs(acc) >= 120 && !flipCooldown.running) {
                        root.goToPage(pageView.currentIndex + (acc < 0 ? 1 : -1));
                        flipCooldown.start();
                        acc = 0;
                    }
                }
            }
            Timer {
                id: flipCooldown
                interval: 300
            }
        }

        Row { // Page dots
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            Layout.bottomMargin: 6
            spacing: 2
            Repeater {
                model: pageView.count
                delegate: Item {
                    id: dot
                    required property int index
                    width: 16
                    height: 16
                    Rectangle {
                        anchors.centerIn: parent
                        width: 7
                        height: 7
                        radius: 3.5
                        color: ColorUtils.transparentize(Appearance.colors.colOnLayer0, dot.index === pageView.currentIndex ? 0.1 : (dotMouse.containsMouse ? 0.5 : 0.75))
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                    MouseArea {
                        id: dotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToPage(dot.index)
                    }
                }
            }
        }

        Rectangle { // Separator
            Layout.fillWidth: true
            implicitHeight: 1
            color: root.colBorder
        }

        RowLayout { // Quick actions
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 0
            Repeater {
                model: [
                    { icon: "calculate", label: Translation.tr("Calculator"), action: () => root.searchRequested(Config.options.search.prefix.math) },
                    { icon: "folder_open", label: Translation.tr("Files"), action: () => { GlobalStates.overviewOpen = false; Quickshell.execDetached(["xdg-open", FileUtils.trimFileProtocol(Directories.home)]); } },
                    { icon: "content_paste", label: Translation.tr("Clipboard"), action: () => root.searchRequested(Config.options.search.prefix.clipboard) },
                    { icon: "mood", label: Translation.tr("Emoji"), action: () => root.searchRequested(Config.options.search.prefix.emojis) },
                    { icon: "power_settings_new", label: Translation.tr("Power"), action: () => { GlobalStates.overviewOpen = false; GlobalStates.sessionOpen = true; } },
                ]
                delegate: Item {
                    id: actionCell
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 36
                    RippleButton {
                        anchors.centerIn: parent
                        implicitHeight: 34
                        implicitWidth: actionRow.implicitWidth + 24
                        buttonRadius: height / 2
                        colBackground: "transparent"
                        colBackgroundHover: root.colHover
                        onClicked: actionCell.modelData.action()
                        contentItem: Row {
                            id: actionRow
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                anchors.verticalCenter: parent.verticalCenter
                                text: actionCell.modelData.icon
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: actionCell.modelData.label
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }
}
