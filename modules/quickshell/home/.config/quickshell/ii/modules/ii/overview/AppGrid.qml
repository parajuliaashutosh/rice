pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Launcher app grid shown under the search bar while nothing is typed:
// favourites first (pinned apps, then common ones that are installed), "All apps" for the rest.
Rectangle {
    id: root
    signal searchRequested(string text)

    property bool showAll: false
    readonly property int columns: 10
    readonly property int favouriteRows: 3
    readonly property real cellHeight: 96

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
        ["libreoffice-startcenter"],
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
        return out.slice(0, root.columns * root.favouriteRows);
    }

    readonly property color colPanel: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerLow, 0.12)

    implicitHeight: content.implicitHeight + 32
    radius: Appearance.rounding.large
    color: colPanel
    border.width: 1
    border.color: Appearance.colors.colLayer0Border

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (!GlobalStates.overviewOpen) root.showAll = false;
        }
    }

    ColumnLayout {
        id: content
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 10

        RowLayout { // Header
            Layout.fillWidth: true
            Layout.leftMargin: 6
            StyledText {
                Layout.fillWidth: true
                text: root.showAll ? Translation.tr("All applications") : Translation.tr("Applications")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
            }
            RippleButton {
                implicitHeight: 28
                implicitWidth: headerButtonRow.implicitWidth + 20
                buttonRadius: height / 2
                colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.3)
                onClicked: root.showAll = !root.showAll
                contentItem: Row {
                    id: headerButtonRow
                    anchors.centerIn: parent
                    spacing: 2
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.showAll ? Translation.tr("Favourites") : Translation.tr("All apps")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer0
                    }
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.showAll ? "expand_less" : "chevron_right"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            implicitHeight: root.showAll ? root.cellHeight * 4.5 : Math.max(1, Math.ceil(count / root.columns)) * root.cellHeight
            cellWidth: width / root.columns
            cellHeight: root.cellHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: root.showAll
            model: root.showAll ? root.allApps : root.favourites
            onModelChanged: positionViewAtBeginning()

            delegate: Item {
                id: appCell
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                RippleButton {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    buttonRadius: Appearance.rounding.normal
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.4)
                    onClicked: {
                        GlobalStates.overviewOpen = false;
                        appCell.modelData.execute();
                    }
                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 10
                        anchors.bottomMargin: 4
                        spacing: 6
                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 44
                            source: Quickshell.iconPath(appCell.modelData.icon, "application-x-executable")
                        }
                        StyledText {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignTop
                            text: appCell.modelData.name
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                    StyledToolTip {
                        text: appCell.modelData.comment || appCell.modelData.name
                    }
                }
            }

            ScrollBar.vertical: StyledScrollBar {
                policy: root.showAll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }
        }

        Rectangle { // Separator
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colLayer0Border
        }

        RowLayout { // Quick actions
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: [
                    { icon: "calculate", label: Translation.tr("Calculator"), action: () => root.searchRequested(Config.options.search.prefix.math) },
                    { icon: "folder_open", label: Translation.tr("Files"), action: () => { GlobalStates.overviewOpen = false; Quickshell.execDetached(["xdg-open", Directories.home.replace(/^file:\/\//, "")]); } },
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
                        colBackgroundHover: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.4)
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
