import QtQuick
import Quickshell.Hyprland

// Page dots: the focused workspace stretches into a capsule.
Item {
    implicitWidth: row.implicitWidth
    implicitHeight: 12

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                id: dot
                required property var modelData

                visible: modelData.id > 0
                width: modelData.focused ? 18 : 6
                height: 6
                radius: 3
                color: modelData.focused ? "#F5FFFFFF" : (ma.containsMouse ? "#99FFFFFF" : "#4DFFFFFF")

                Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dot.modelData.activate()
                }
            }
        }
    }
}
