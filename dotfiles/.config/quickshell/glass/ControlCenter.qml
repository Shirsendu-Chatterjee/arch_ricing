import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Io

// Glass panel dropped from the right pill. It is a layer-shell window in the
// same namespace as the bar, so Hyprland's layer rule blurs it too.
PanelWindow {
    id: root
	

        // ---- brightness ----
    property real brightness: 0.5   // 0.0–1.0, kept in sync with the OS

    Process {
        id: setBrightnessProc
    }
    function applyBrightness(pct) {
        setBrightnessProc.command = ["brightnessctl", "set", pct + "%"]
        setBrightnessProc.running = true
    }

    Process {
        id: getBrightnessProc
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            // machine format: device,class,current,percentage%,max
            onStreamFinished: {
                const pct = parseInt(text.trim().split(",")[3])
                if (!isNaN(pct)) root.brightness = pct / 100
            }
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: getBrightnessProc.running = true
    }


    property var barWindow
    property real topOffset: 34
    property bool open: false
    property real closedAt: 0

 
    // ---- volume ----
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }



    screen: barWindow.screen
    visible: open
    anchors { top: true; right: true }
    margins { top: topOffset; right: 0 }
    implicitWidth: 320
    implicitHeight: 290
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "qs-glass"
    WlrLayershell.layer: WlrLayer.Overlay

    onOpenChanged: {
        if (open) openAnim.restart()
        else closedAt = Date.now()
    }

    HyprlandFocusGrab {
        windows: [ root ]
        active: root.open
        onCleared: root.open = false
    }

//    BackgroundEffect.blurRegion: Region { item: card; radius: 24 }

          BackgroundEffect.blurRegion: Region { item: root.contentItem; radius: 24 }

    // ---- live state (official Quickshell.Networking / Quickshell.Bluetooth) ----
    readonly property var bt: Bluetooth.defaultAdapter

    function wifiName() {
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue
            const n = d.networks.values.find(x => x.connected)
            if (n) return n.name
        }
        return ""
    }

    readonly property string wifiSub: !Networking.wifiEnabled ? "Off" : (wifiName() || "Not connected")
    readonly property string btSub: !bt ? "Unavailable"
        : !bt.enabled ? "Off"
        : (Bluetooth.devices.values.length > 0 ? Bluetooth.devices.values.length + " connected" : "On")

    component Tile: Rectangle {
        id: t
        property string label
        property string sub
        property bool on: false
        signal toggled()
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 20
        color: on ? "#EBFFFFFF" : (th.hovered ? "#30FFFFFF" : "#1FFFFFFF")
        border.width: 1
        border.color: "#22FFFFFF"
        Behavior on color { ColorAnimation { duration: 180 } }
        Column {
            anchors { left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                text: t.label
                width: parent.width
                elide: Text.ElideRight
                color: t.on ? "#E6101216" : "#E6FFFFFF"
                font.family: "Inter"; font.pixelSize: 13; font.weight: Font.DemiBold
            }
            Text {
                text: t.sub
                width: parent.width
                elide: Text.ElideRight
                color: t.on ? "#99101216" : "#99FFFFFF"
                font.family: "Inter"; font.pixelSize: 11
            }
        }
        HoverHandler { id: th; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: t.toggled() }
    }

    component Track: Item {
        id: tr
        property real value: 0.5
        signal moved(real value)

        property bool dragging: false
        property real dragValue: value
        readonly property real displayValue: dragging ? dragValue : value

        Layout.fillWidth: true
        Layout.preferredHeight: 24
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "#1FFFFFFF"
            border.width: 1
            border.color: "#1AFFFFFF"
        }
        Rectangle {
            width: Math.max(parent.height, parent.width * tr.displayValue)
            height: parent.height
            radius: height / 2
            color: "#E6FFFFFF"
            Behavior on width { enabled: !tr.dragging; NumberAnimation { duration: 120 } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function posToValue(x) { return Math.min(1, Math.max(0, x / width)) }
            onPressed: mouse => { tr.dragging = true; tr.dragValue = posToValue(mouse.x); tr.moved(tr.dragValue) }
            onPositionChanged: mouse => { if (tr.dragging) { tr.dragValue = posToValue(mouse.x); tr.moved(tr.dragValue) } }
            onReleased: tr.dragging = false
            onCanceled: tr.dragging = false
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: card
            x: 10; y: 10
            width: parent.width - 20
            height: parent.height - 20
            radius: 24
            visible: false
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6E2B303B" }
                GradientStop { position: 1.0; color: "#5C181B23" }
            }
        }

        property real p: 0
        NumberAnimation on p { id: openAnim; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic; running: false }

        Item {
            anchors.fill: parent
            opacity: parent.p
            scale: 0.94 + 0.06 * parent.p
            transformOrigin: Item.TopRight

            MultiEffect {
                anchors.fill: card
                source: card
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.30
                shadowBlur: 1.0
                shadowVerticalOffset: 6
            }
            Rectangle {
                x: card.x; y: card.y; width: card.width; height: card.height
                radius: card.radius
                color: "transparent"
                border.width: 1
                border.color: "#38FFFFFF"
            }
            Rectangle {
                height: 1
                x: card.x + 24; y: card.y + 1
                width: card.width - 48
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#00FFFFFF" }
                    GradientStop { position: 0.5; color: "#70FFFFFF" }
                    GradientStop { position: 1.0; color: "#00FFFFFF" }
                }
            }

            ColumnLayout {
                x: card.x + 18; y: card.y + 16
                width: card.width - 36
                spacing: 10

                Text {
                    text: "Control Center"
                    color: "#F2FFFFFF"
                    font.family: "Inter"; font.pixelSize: 14; font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Tile {
                        label: "Wi-Fi"
                        sub: root.wifiSub
                        on: Networking.wifiEnabled
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                    Tile {
                        label: "Bluetooth"
                        sub: root.btSub
                        on: root.bt ? root.bt.enabled : false
                        onToggled: { if (root.bt) root.bt.enabled = !root.bt.enabled }
                    }
                }
                Text {
                    text: "Brightness  " + Math.round(root.brightness * 100) + "%"
                    color: "#99FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium
                }
                Track {
                    value: root.brightness
                    onMoved: v => {
                        root.brightness = v
                        applyBrightness(Math.round(v * 100))
                    }
                }
                 Text {
                     text: "Volume  " + (root.sink ? Math.round(root.sink.audio.volume * 100) : 0) + "%"
                     color: "#99FFFFFF"; font.family: "Inter"; font.pixelSize: 11; font.weight: Font.Medium
                 }
                 Track {
                     value: root.sink ? root.sink.audio.volume : 0
                     onMoved: v => { if (root.sink) root.sink.audio.volume = v }
                }
            }
        }
    }
}

