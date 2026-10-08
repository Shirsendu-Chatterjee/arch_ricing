import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property var barWindow
    property bool open: false

    screen: barWindow ? barWindow.screen : null

    visible: open

    anchors {
        top: true
        bottom: true
        left: true
    }

    margins {
        top: 52
        bottom: 10
        left: 10
    }

    implicitWidth: 420

    exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    WlrLayershell.namespace: "qs-glass"
    WlrLayershell.layer: WlrLayer.Overlay

    property real progress: 0

    onOpenChanged: {
        if (open) {
            progress = 0
            openAnimation.restart()
        }
    }

    NumberAnimation {
        id: openAnimation

        target: root
        property: "progress"

        from: 0
        to: 1

        duration: 280

        easing.type: Easing.OutCubic
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open

        onCleared: {
            root.open = false
        }
    }

    BackgroundEffect.blurRegion: Region {
        item: card
        radius: card.radius
    }

    Item {
        anchors.fill: parent

        opacity: root.progress

        scale: 0.94 + 0.06 * root.progress

        transformOrigin: Item.TopLeft

        Rectangle {
            id: card

            x: 0
            y: 0

            width: parent.width
            height: parent.height

            radius: 24

            visible: false

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#6E2B303B"
                }

                GradientStop {
                    position: 1.0
                    color: "#5C181B23"
                }
            }
        }

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
            anchors.fill: card

            radius: card.radius

            color: "transparent"

            border.width: 1
            border.color: "#38FFFFFF"
        }

        Rectangle {
            height: 1

            anchors {
                top: card.top
                topMargin: 1
                left: card.left
                leftMargin: 28
                right: card.right
                rightMargin: 28
            }

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0.0
                    color: "#00FFFFFF"
                }

                GradientStop {
                    position: 0.5
                    color: "#70FFFFFF"
                }

                GradientStop {
                    position: 1.0
                    color: "#00FFFFFF"
                }
            }
        }

        ColumnLayout {
            anchors {
                left: card.left
                right: card.right
                top: card.top
                bottom: card.bottom

                leftMargin: 18
                rightMargin: 18
                topMargin: 16
                bottomMargin: 16
            }

            spacing: 12

            // =================================================
            // HEADER
            // =================================================

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "AI Assistant"

                    color: "#F2FFFFFF"

                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold

                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30

                    radius: 15

                    color: closeHover.hovered
                           ? "#30FFFFFF"
                           : "#18FFFFFF"

                    border.width: 1
                    border.color: "#30FFFFFF"

                    Text {
                        anchors.centerIn: parent

                        text: "×"

                        color: "#E6FFFFFF"

                        font.family: "Inter"
                        font.pixelSize: 19
                    }

                    HoverHandler {
                        id: closeHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            root.open = false
                        }
                    }
                }
            }

            // =================================================
            // CHAT AREA
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: 20

                color: "#18000000"

                border.width: 1
                border.color: "#20FFFFFF"

                ListView {
                    id: messages

                    anchors.fill: parent

                    anchors.margins: 12

                    clip: true

                    spacing: 10

                    model: ListModel {
                        id: chatModel

                        ListElement {
                            role: "assistant"
                            message: "Hello. I'm your system assistant."
                        }
                    }

                    delegate: Item {
                        width: messages.width

                        implicitHeight: bubble.height + 4

                        Rectangle {
                            id: bubble

                            width: Math.min(
                                messages.width * 0.82,
                                messageText.implicitWidth + 28
                            )

                            height: messageText.implicitHeight + 20

                            radius: 16

                            anchors.left: model.role === "assistant"
                                         ? parent.left
                                         : undefined

                            anchors.right: model.role === "user"
                                          ? parent.right
                                          : undefined

                            color: model.role === "user"
                                   ? "#38FFFFFF"
                                   : "#20FFFFFF"

                            border.width: 1
                            border.color: "#28FFFFFF"

                            Text {
                                id: messageText

                                anchors.fill: parent

                                anchors.margins: 14

                                text: model.message

                                color: "#E8FFFFFF"

                                font.family: "Inter"
                                font.pixelSize: 12

                                wrapMode: Text.Wrap

                                lineHeight: 1.2
                            }
                        }
                    }

                    onCountChanged: {
                        Qt.callLater(function() {
                            positionViewAtEnd()
                        })
                    }
                }
            }

            // =================================================
            // INPUT
            // =================================================

            Rectangle {
                Layout.fillWidth: true

                Layout.preferredHeight: 50

                radius: 18

                color: "#22FFFFFF"

                border.width: 1
                border.color: "#30FFFFFF"

                RowLayout {
                    anchors.fill: parent

                    anchors.leftMargin: 14
                    anchors.rightMargin: 8

                    spacing: 8

                    TextField {
                        id: input

                        Layout.fillWidth: true

                        placeholderText: "Ask your system..."

                        placeholderTextColor: "#70FFFFFF"

                        color: "#F0FFFFFF"

                        font.family: "Inter"
                        font.pixelSize: 12

                        background: Item {}

                        selectByMouse: true

                        Keys.onReturnPressed: {
                            root.sendMessage()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34

                        radius: 17

                        color: sendHover.hovered
                               ? "#45FFFFFF"
                               : "#28FFFFFF"

                        border.width: 1
                        border.color: "#30FFFFFF"

                        Text {
                            anchors.centerIn: parent

                            text: "↑"

                            color: "#EFFFFFFF"

                            font.family: "Inter"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        HoverHandler {
                            id: sendHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                root.sendMessage()
                            }
                        }
                    }
                }
            }
        }
    }


function sendMessage() {
    const text = input.text.trim()

    if (text.length === 0)
        return

    // Add the user's message immediately.
    chatModel.append({
        role: "user",
        message: text
    })

    input.clear()

    // Create an HTTP request to the local Python backend.
    const xhr = new XMLHttpRequest()

    xhr.open(
        "POST",
        "http://127.0.0.1:8765/chat"
    )

    xhr.setRequestHeader(
        "Content-Type",
        "application/json"
    )

    // This function runs when Python responds.
    xhr.onreadystatechange = function() {

        // The request isn't finished yet.
        if (xhr.readyState !== XMLHttpRequest.DONE)
            return

        // Python successfully responded.
        if (xhr.status === 200) {

            const result = JSON.parse(
                xhr.responseText
            )

            chatModel.append({
                role: "assistant",
                message: result.response
            })

            messages.positionViewAtEnd()

        } else {

            // Something went wrong.
            chatModel.append({
                role: "assistant",
                message:
                    "Backend error (" +
                    xhr.status +
                    ")"
            })

            messages.positionViewAtEnd()
        }
    }

    // Send JSON to FastAPI.
    xhr.send(
        JSON.stringify({
            message: text
        })
    )
}}
