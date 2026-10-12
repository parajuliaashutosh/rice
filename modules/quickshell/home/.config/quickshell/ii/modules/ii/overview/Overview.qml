import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    // Super+V / Super+. open just the search box; leaving their prefix (e.g. backspacing it)
    // expands into the full launcher
    property bool compact: false

    PanelWindow {
        id: panelWindow
        property string searchingText: ""
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        // Launcher content width: strip and app panel line up, with a comfortable side margin.
        // From the screen, not the window: the window shrinks to nothing while hidden, and a
        // width change there rebuilt every app page and thumbnail on each open (~0.6s).
        readonly property real contentWidth: Math.min(1760, screen.width - 2 * Math.max(48, screen.width * 0.06))
        // 0 = compact, 1 = full launcher (backdrop, strip and app panel); animated on expand
        property real expand: 1
        NumberAnimation {
            id: expandAnim
            target: panelWindow
            property: "expand"
            to: 1
            duration: 260
            easing.type: Easing.OutCubic
        }
        Connections {
            target: overviewScope
            function onCompactChanged() {
                expandAnim.stop();
                if (overviewScope.compact) panelWindow.expand = 0;
                else if (GlobalStates.overviewOpen) expandAnim.restart();
                else panelWindow.expand = 1;
            }
        }
        onSearchingTextChanged: {
            const prefix = Config.options.search.prefix;
            if (overviewScope.compact && !searchingText.startsWith(prefix.clipboard) && !searchingText.startsWith(prefix.emojis))
                overviewScope.compact = false;
        }

        mask: Region {
            item: GlobalStates.overviewOpen ? clickCatcher : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    overviewScope.compact = false;
                    GlobalFocusGrab.dismiss();
                } else {
                    if (!overviewScope.dontAutoCancelSearch) {
                        overviewScope.compact = false;
                        searchWidget.cancelSearch();
                    }
                    GlobalFocusGrab.addDismissable(panelWindow);
                    revealAnim.restart();
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text);
            searchWidget.focusFirstItem();
        }

        // Clicks anywhere outside the launcher content close it (including the gaps)
        MouseArea {
            id: clickCatcher
            anchors.fill: parent
            onClicked: GlobalStates.overviewOpen = false
        }

        // Backdrop: a wallpaper-tinted veil; Hyprland blurs what's behind it (rules.lua).
        // Inset and rounded like a tiled window (general.lua: gaps_out = 5, rounding = 18).
        Rectangle {
            id: backdrop
            anchors {
                fill: parent
                margins: 5
            }
            // No fade: everything appears at once, so nothing flickers in while it settles
            visible: GlobalStates.overviewOpen && panelWindow.expand > 0
            opacity: panelWindow.expand
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, 0.35)
            radius: 18
        }

        // Launcher: workspace strip, search bar, then the app grid (hidden while searching)
        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Math.max(28, (panelWindow.height - 760) / 3) // a little above centre
            }
            spacing: 22

            // Opening: the content eases up and in while Hyprland fades the backdrop (rules.lua)
            property real reveal: 1
            opacity: reveal
            scale: 0.965 + 0.035 * reveal
            // Compact mode lifts the search box to just under the bar (the hidden strip goes
            // off the top); expanding slides it back down into place
            readonly property real compactLift: anchors.topMargin + stripLoader.height + spacing - 6
            transform: Translate {
                y: (1 - columnLayout.reveal) * (overviewScope.compact ? -16 : 24) - (1 - panelWindow.expand) * columnLayout.compactLift
            }
            NumberAnimation {
                id: revealAnim
                target: columnLayout
                property: "reveal"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                }
            }

            Loader {
                id: stripLoader
                anchors.horizontalCenter: parent.horizontalCenter
                // Hidden but still taking its space in compact mode, so the search box stays put
                opacity: panelWindow.expand
                enabled: !overviewScope.compact
                transform: Translate {
                    y: (1 - panelWindow.expand) * -20
                }
                // Kept loaded between opens so the thumbnails don't pop in each time
                active: Config?.options.overview.enable ?? true
                sourceComponent: WorkspaceStrip {
                    screen: panelWindow.screen
                    width: panelWindow.contentWidth
                }
            }

            SearchWidget {
                id: searchWidget
                anchors.horizontalCenter: parent.horizontalCenter
                Synchronizer on searchingText {
                    property alias source: panelWindow.searchingText
                }
            }

            Loader {
                id: appGridLoader
                anchors.horizontalCenter: parent.horizontalCenter
                visible: panelWindow.searchingText == "" && !overviewScope.compact
                opacity: panelWindow.expand
                transform: Translate {
                    y: (1 - panelWindow.expand) * 28
                }
                sourceComponent: AppGrid {
                    width: panelWindow.contentWidth
                    onSearchRequested: text => panelWindow.setSearchingText(text)
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        if (!GlobalStates.overviewOpen) overviewScope.compact = true;
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        if (!GlobalStates.overviewOpen) overviewScope.compact = true;
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}
