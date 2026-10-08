import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.UPower

PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property int margin: 6
    readonly property int edge: 10
    property real reveal: 0
    NumberAnimation on reveal { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }

    anchors { top: true; left: true; right: true }
    implicitHeight: 52          // 6 + 30 pill + shadow room
    exclusiveZone: 42           // space reserved for tiled windows
    color: "transparent"

    WlrLayershell.namespace: "qs-glass"

    // Only the pills take input; the rest of the strip is click-through.
    mask: Region {
        Region {item: aiPill; radius: aiPill.radius}
        Region { item: leftPill;   radius: leftPill.radius }
        Region { item: centerPill; radius: centerPill.radius }
        Region { item: rightPill;  radius: rightPill.radius }
    }

    // Blur via ext-background-effect-v1 when the compositor supports it;
    // the Hyprland layer rule covers the rest.
    BackgroundEffect.blurRegion: Region {
        Region { item: leftPill;   radius: leftPill.radius }
        Region { item: centerPill; radius: centerPill.radius }
 	Region { item: statusPill; radius: statusPill.radius }   
        Region { item: rightPill;  radius: rightPill.radius }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
	
        // ── system stats ──
    property real cpu: 0
    property real ram: 0
    property var lastCpu: [0, 0]          // [idle, total] from the previous tick
    readonly property var bat: UPower.displayDevice

    FileView { id: statFile; path: "/proc/stat";    blockLoading: true }
    FileView { id: memFile;  path: "/proc/meminfo"; blockLoading: true }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            statFile.reload(); memFile.reload()

            const c = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = c[3] + c[4]                       // idle + iowait
            const total = c.reduce((a, b) => a + b, 0)
            if (win.lastCpu[1] > 0)
                win.cpu = 1 - (idle - win.lastCpu[0]) / (total - win.lastCpu[1])
            win.lastCpu = [idle, total]

            const m = memFile.text()
            win.ram = 1 - m.match(/MemAvailable:\s+(\d+)/)[1] / m.match(/MemTotal:\s+(\d+)/)[1]
        }
    }

    GlassPill {
    id: aiPill

    interactive: true

    implicitWidth: 38

    opacity: win.reveal

    anchors {
        left: parent.left
        leftMargin: win.edge

        top: parent.top
        topMargin: win.margin - (1 - win.reveal) * 12
    }

    onClicked: {
        chat.open = !chat.open
    }

    Text {
        anchors.centerIn: parent

        text: "✦" 

        color: "#EFFFFFFF"

        font.family: "Inter"
        font.pixelSize: 16
        font.weight: Font.DemiBold
    }
}





    GlassPill {
      id: leftPill
        opacity: win.reveal
        anchors {
            left: aiPill.right
            leftMargin: 8
            top: parent.top; topMargin: win.margin - (1 - win.reveal) * 12
        }

        Workspaces {}
        Rectangle { implicitWidth: 1; implicitHeight: 12; color: "#26FFFFFF" }
        Text {
            text: Hyprland.activeToplevel?.title || "Desktop"
            color: "#E6FFFFFF"
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.maximumWidth: 260
        }
    }

    GlassPill {
        id: centerPill
        opacity: win.reveal
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top; topMargin: win.margin - (1 - win.reveal) * 12
        }

        Text {
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: "#99FFFFFF"
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: "#FFFFFFFF"
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }


        GlassPill {
        id: statusPill
        opacity: win.reveal
        anchors {
            right: rightPill.left; rightMargin: 8
            top: parent.top; topMargin: win.margin - (1 - win.reveal) * 12
        }

        Text {
            text: "CPU " + Math.round(win.cpu * 100) + "%"
            color: "#E6FFFFFF"
            font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium
        }
        Text {
            text: "RAM " + Math.round(win.ram * 100) + "%"
            color: "#E6FFFFFF"
            font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium
        }
        Text {
            visible: win.bat.isPresent
            text: "BAT " + Math.round(win.bat.percentage * 100) + "%"
            color: win.bat.state === UPowerDeviceState.Charging ? "#FF9BE8A8" : "#E6FFFFFF"
            font.family: "Inter"; font.pixelSize: 12; font.weight: Font.Medium
        }
    }




    GlassPill {
        id: rightPill
        interactive: true
        implicitWidth: 38
        opacity: win.reveal
        anchors {
            right: parent.right; rightMargin: win.edge
            top: parent.top; topMargin: win.margin - (1 - win.reveal) * 12
        }

        onClicked: {
            if (cc.open) cc.open = false
            else if (Date.now() - cc.closedAt > 250) cc.open = true   // ignore the click that just dismissed it
        }

        Item {
            implicitWidth: 14
            implicitHeight: 12
            Rectangle {
                y: 0; width: 14; height: 5; radius: 2.5; color: "#40FFFFFF"
                Rectangle { x: 9.5; y: 1; width: 3; height: 3; radius: 1.5; color: "white" }
            }
            Rectangle {
                y: 7; width: 14; height: 5; radius: 2.5; color: "#40FFFFFF"
                Rectangle { x: 1.5; y: 1; width: 3; height: 3; radius: 1.5; color: "white" }
            }
        }
    }

    ControlCenter {
        id: cc
        barWindow: win
        topOffset: win.margin + 30 - 2
    }
  


  ChatPanel {
    id: chat

    barWindow: win
  }
}
