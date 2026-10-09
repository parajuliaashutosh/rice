import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Live download / upload, styled like the Resource rings.
// Each ring fills relative to the busiest second seen recently, so it reads as "how busy right now".
MouseArea {
    id: root
    readonly property bool connected: Network.ethernet || (Network.wifiEnabled && Network.wifiStatus === "connected")
    property real rxRate: 0 // bytes/s
    property real txRate: 0
    property real rxPeak: 128 * 1024
    property real txPeak: 32 * 1024
    property var lastSample: null

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function formatRate(bytes) {
        const k = bytes / 1024;
        if (k < 1000) return `${Math.round(k)}K`;
        const m = k / 1024;
        return m < 10 ? `${m.toFixed(1)}M` : `${Math.round(m)}M`;
    }

    FileView {
        id: netDev
        path: "/proc/net/dev"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netDev.reload();
            let rx = 0, tx = 0;
            for (const line of netDev.text().split("\n").slice(2)) {
                const [iface, data] = line.split(":");
                if (!data || iface.trim() === "lo") continue;
                const f = data.trim().split(/\s+/);
                rx += Number(f[0]);
                tx += Number(f[8]);
            }
            const now = Date.now();
            if (root.lastSample) {
                const dt = (now - root.lastSample.t) / 1000;
                root.rxRate = Math.max(0, (rx - root.lastSample.rx) / dt);
                root.txRate = Math.max(0, (tx - root.lastSample.tx) / dt);
                // Peaks decay slowly so the rings rescale after a burst
                root.rxPeak = Math.max(128 * 1024, root.rxRate, root.rxPeak * 0.97);
                root.txPeak = Math.max(32 * 1024, root.txRate, root.txPeak * 0.97);
            }
            root.lastSample = { t: now, rx: rx, tx: tx };
        }
    }

    component RateRing: RowLayout {
        id: ring
        required property string iconName
        required property real rate
        required property real peak
        spacing: 2

        ClippedFilledCircularProgress {
            id: circProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: Math.min(1, ring.rate / ring.peak)
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            accountForLightBleeding: true
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: circProg.implicitSize
                height: circProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: ring.iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: rateTextMetrics.width
            implicitHeight: rateText.implicitHeight

            TextMetrics {
                id: rateTextMetrics
                text: "999K"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: rateText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.formatRate(ring.rate)
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        RateRing {
            iconName: "arrow_downward"
            rate: root.rxRate
            peak: root.rxPeak
        }

        RateRing {
            iconName: "arrow_upward"
            rate: root.txRate
            peak: root.txPeak
        }
    }

    StyledPopup {
        hoverTarget: root

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            StyledPopupHeaderRow {
                icon: Network.materialSymbol
                label: Network.ethernet ? Translation.tr("Ethernet") : (root.connected ? Network.networkName : Translation.tr("Disconnected"))
            }
            StyledPopupValueRow {
                visible: !Network.ethernet && root.connected
                icon: "network_wifi"
                label: Translation.tr("Signal:")
                value: `${Network.networkStrength}%`
            }
            StyledPopupValueRow {
                icon: "download"
                label: Translation.tr("Download:")
                value: `${root.formatRate(root.rxRate)}/s`
            }
            StyledPopupValueRow {
                icon: "upload"
                label: Translation.tr("Upload:")
                value: `${root.formatRate(root.txRate)}/s`
            }
        }
    }
}
