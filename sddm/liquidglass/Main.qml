import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects 6.5

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0d0d0f"

    property color accent: config.AccentColor || "#7aa2f7"
    property real cardRadius: parseInt(config.CornerRadius) || 32
    property color glassTint: config.GlassTint || "#ffffff"
    property real glassOpacity: parseFloat(config.GlassOpacity) || 0.10

    // ---------- Background ----------
    Image {
        id: bgImage
        anchors.fill: parent
        source: config.Background !== "" ? "file://" + config.Background : ""
        fillMode: Image.PreserveAspectCrop
        visible: config.Background !== ""
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        visible: config.Background === ""
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1a2e" }
            GradientStop { position: 1.0; color: "#0d0d0f" }
        }
    }

    ShaderEffectSource {
        id: bgSource
        sourceItem: config.Background !== "" ? bgImage : bgFallback
        anchors.fill: card
        sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
        hideSource: false
        visible: false
    }

    Rectangle {
        id: bgFallback
        anchors.fill: parent
        visible: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1a1a2e" }
            GradientStop { position: 1.0; color: "#0d0d0f" }
        }
    }

    FastBlur {
        id: blurred
        anchors.fill: card
        source: bgSource
        radius: 48
        visible: false
    }

    OpacityMask {
        anchors.fill: card
        source: blurred
        maskSource: cardMask
    }

    Rectangle {
        id: cardMask
        anchors.fill: card
        radius: cardRadius
        visible: false
    }

    // ---------- Live clock ----------
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12
        color: "white"
        font.family: config.FontFamily || "Noto Sans"
        font.pixelSize: 108
        font.weight: Font.Light
        text: Qt.formatTime(clockTimer.now, config.ClockFormat || "hh:mm")

        Timer {
            id: clockTimer
            property date now: new Date()
            interval: 1000
            running: true
            repeat: true
            onTriggered: now = new Date()
        }
    }

    // ---------- Glass login card ----------
    Rectangle {
        id: card
        width: 600
        height: content.implicitHeight + 80
        radius: cardRadius
        anchors.centerIn: parent
        color: Qt.rgba(glassTint.r, glassTint.g, glassTint.b, glassOpacity)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 28
            samples: 36
            color: "#66000000"
            verticalOffset: 10
        }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            width: parent.width - 80
            spacing: 22

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 112
                height: 112
                radius: 56
                color: Qt.rgba(1, 1, 1, 0.12)
                border.color: Qt.rgba(1, 1, 1, 0.2)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: userCombo.currentText.length > 0 ? userCombo.currentText.charAt(0).toUpperCase() : "?"
                    color: "white"
                    font.pixelSize: 46
                    font.weight: Font.DemiBold
                }
            }

            ComboBox {
                id: userCombo
                Layout.fillWidth: true
                implicitHeight: 62
                font.pixelSize: 20
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                background: Rectangle {
                    color: Qt.rgba(1, 1, 1, 0.08)
                    radius: 14
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                }
                contentItem: Text {
                    text: userCombo.displayText
                    color: "white"
                    font: userCombo.font
                    leftPadding: 16
                    verticalAlignment: Text.AlignVCenter
                }
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                implicitHeight: 62
                font.pixelSize: 20
                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                color: "white"
                background: Rectangle {
                    color: Qt.rgba(1, 1, 1, 0.08)
                    radius: 14
                    border.color: passwordField.activeFocus ? accent : Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                }
                leftPadding: 16
                Keys.onReturnPressed: loginButton.clicked()
                Keys.onEnterPressed: loginButton.clicked()
                Component.onCompleted: forceActiveFocus()
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: keyboard.capsLock
                text: "Caps Lock is on"
                color: "#e06c75"
                font.pixelSize: 18
            }

            Text {
                id: errorText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: "#e06c75"
                font.pixelSize: 18
                text: ""
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                implicitHeight: 62
                text: "Log In"
                onClicked: {
                    errorText.text = ""
                    sddm.login(userCombo.currentText, passwordField.text, sessionCombo.currentIndex)
                }
                background: Rectangle {
                    radius: 14
                    color: accent
                }
                contentItem: Text {
                    anchors.fill: parent
                    text: loginButton.text
                    color: "#0d0d0f"
                    font.pixelSize: 23
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ComboBox {
                id: sessionCombo
                Layout.fillWidth: true
                implicitHeight: 48
                visible: config.ShowSessionPicker === "true"
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                background: Rectangle {
                    color: "transparent"
                }
                contentItem: Text {
                    text: sessionCombo.displayText
                    color: Qt.rgba(1, 1, 1, 0.7)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 17
                }
            }
        }
    }

    // ---------- Power buttons ----------
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 36
        spacing: 18

        Button {
            visible: sddm.canReboot
            text: "⟳"
            implicitWidth: 68
            implicitHeight: 68
            onClicked: sddm.reboot()
            background: Rectangle { radius: 34; color: Qt.rgba(1, 1, 1, 0.08) }
            contentItem: Text {
                anchors.fill: parent
                text: parent.text
                color: "white"
                font.pixelSize: 30
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
        Button {
            visible: sddm.canPowerOff
            text: "⏻"
            implicitWidth: 68
            implicitHeight: 68
            onClicked: sddm.powerOff()
            background: Rectangle { radius: 34; color: Qt.rgba(1, 1, 1, 0.08) }
            contentItem: Text {
                anchors.fill: parent
                text: parent.text
                color: "white"
                font.pixelSize: 30
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorText.text = "Login failed — try again"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }
}
