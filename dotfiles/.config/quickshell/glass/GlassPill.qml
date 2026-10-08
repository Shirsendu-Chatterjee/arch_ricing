import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// One floating glass capsule. Children go into a centered RowLayout.
Item {
    id: root

    default property alias content: row.data
    property real radius: height / 2
    property real hPadding: 14
    property bool interactive: false
    readonly property bool hovered: hover.hovered
    signal clicked()

    implicitHeight: 30
    implicitWidth: row.implicitWidth + hPadding * 2

    scale: interactive && tap.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        visible: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#5E2B303B" }
            GradientStop { position: 1.0; color: "#4F181B23" }
        }
    }

    MultiEffect {
        anchors.fill: body
        source: body
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.28
        shadowBlur: 1.0
        shadowVerticalOffset: 4
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "white"
        opacity: root.interactive && root.hovered ? 0.10 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: "#38FFFFFF"
    }

    Rectangle {
        height: 1
        anchors {
            top: parent.top; topMargin: 1
            left: parent.left; leftMargin: root.radius * 0.7
            right: parent.right; rightMargin: root.radius * 0.7
        }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00FFFFFF" }
            GradientStop { position: 0.5; color: "#70FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }

    HoverHandler { id: hover; cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { id: tap; enabled: root.interactive; onTapped: root.clicked() }
}
