import QtQuick 1.1
import "functions.js" as Lib
import CursorShape 1.0
import StandardToolTip 1.0

/* Panel.qml */
MouseArea {
    id: panel
    hoverEnabled: true
    
    property bool hasQualityList: qualities.length > 0
    property variant qualities: 0                    // qualities array
    property variant bitrates: 0                     // bitrates array

    /* menu quality functions */
    function initQualityMenu() {
        for(var i = 0; i < panel.qualities.length; i++) {
            qList.children[i].name = panel.qualities[i];
            qList.children[i].bitrate = panel.bitrates[i];
            qList.children[i].visible = true;
            qList.children[i].hovered = false;
        }
        chooseQuality.visible = true;
    }

    function uninitQualityMenu() {
        chooseQuality.visible = false;
        for(var i = 0; i < chooseQuality.itemsCount; i++) {
            qList.children[i].hovered = false;
            qList.children[i].visible = false;
        }
    }

    /* popup */
    Image {
        id: popup
        y: playbackProgressBar.y - height
        width: player.minPanel || player.hasInteractive ? panel.height * 1.5 : panel.height*0.5365
        height: width * 0.4078
        source: root.imgPath + "popup.png"
        opacity: 0
        smooth: true

        states: [
            State { name: "showpopup";
                when: playbackProgressBarArea.containsMouse && player.state < playerstates.prebuffering },
            State { name: "hidepopup";
                when: !playbackProgressBarArea.containsMouse && player.state < playerstates.prebuffering }
        ]
        transitions: [
            Transition {
                from: "hidepopup"; to: "showpopup"
                NumberAnimation {
                    target: popup
                    properties: "opacity"
                    from: 0; to: 1; duration: 500
                }
            },
            Transition {
                from: "showpopup"; to: "hidepopup"
                NumberAnimation {
                    target: popup
                    properties: "opacity"
                    from: 1; to: 0; duration: 500
                }
            }
        ]

        Text {
            id: lblPopup
            y: (parent.height - parent.height * 0.1429 - height) / 2
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: parent.height * 0.4762
            color: "#e5e5e5"
            text: ""
        }
    }

    /* panel view */
    Column {
        id: panelMainLayout
        anchors.fill: parent
        spacing: 0

        /* playback progress bar (top panel area) */
        Rectangle {
            id: playbackProgressBar
            width: parent.width
            height: player.minPanel || player.hasInteractive ? Math.floor(panel.height * 0.25) : Math.floor(panel.height * 0.0625)
            color: "#676767"
            opacity: 0.45

            MouseArea {
                id: playbackProgressBarArea
                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if( player.state > playerstates.paused ) return;
                    var newPlayback = mouseX / playbackProgressBar.width;
                    if( player.liveStream )
                        lblPopup.text = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                    else
                        lblPopup.text = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                    player.changePlayback(newPlayback);
                }
                onMousePositionChanged: {
                    if( player.state > playerstates.paused ) return;
                    var newPlayback = mouseX / playbackProgressBar.width;
                    if( player.liveStream )
                        lblPopup.text = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                    else
                        lblPopup.text = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                    popup.x = mouseX - popup.width / 2
                }

                /* playback progress bar value */
                Rectangle {
                    id: playbackProgressBarValue
                    width: player.playback * parent.width
                    height: parent.height
                    opacity: 1
                    color: player.liveStream ? "#676767" : "#498C9F"
                }

                /* playback live indicator */
                Rectangle {
                    id: playbackProgressBarLiveIndicator
                    x: parent.width - width
                    width: parent.width - playbackProgressBarValue.width
                    height: parent.height
                    opacity: 1
                    color: player.liveStreamIsLive == -1 ? "#676767" : player.liveStream ? "#dd9a22" : "#676767"
                }

                /* buffer live indicator */
                Rectangle {
                    id: playbackProgressBarLiveBufferIndicator
                    x: parent.width - width
                    width: parent.width - player.liveBufferPos * parent.width
                    height: parent.height
                    opacity: 1
                    color: player.liveStreamIsLive == -1 ? "#676767" : player.liveStream ? "#498C9F" : "#676767"
                }

                /* playback progress bar slider */
                Rectangle {
                    id: playbackProgressBarSlider
                    x: playbackProgressBarSliderArea.drag.active ? x : playbackProgressBarValue.width - width / 2
                    width: height
                    height: parent.height
                    color: "#e5e5e5"

                    MouseArea {
                        id: playbackProgressBarSliderArea
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0 - playbackProgressBarSlider.width / 2
                        drag.maximumX: ( player.state > playerstates.paused ) ? drag.minimumX : playbackProgressBar.width - playbackProgressBarSlider.width / 2

                        onPositionChanged: {
                            if( player.state > playerstates.paused ) return;
                            var newPlayback = (playbackProgressBarSlider.x + playbackProgressBarSlider.width / 2) / playbackProgressBar.width;
                            if( player.liveStream )
                                lblPopup.text = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                            else
                                lblPopup.text = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                            popup.x = playbackProgressBarSlider.x + playbackProgressBarSlider.width / 2 - popup.width / 2
                        }

                        onReleased: {
                            if( player.state > playerstates.paused ) return;
                            var newPlayback = (playbackProgressBarSlider.x + playbackProgressBarSlider.width / 2) / playbackProgressBar.width;
                            player.checkPlayback(newPlayback);
                        }
                    }
                }
            }
        }

        /* central panel area */
        Rectangle {
            id: centralArea
            width: parent.width
            height: Math.floor(parent.height * 0.7552)
            color: "#444444"
            visible: !player.minPanel && !player.hasInteractive
            opacity: 0.45

            /* buttons */
            Row {
                id: buttons_row
                anchors.centerIn: parent
                spacing: Math.floor(btnStop.height * 0.65)

                /* stop button */
                Button {
                    id: btnStop
                    anchors.verticalCenter: parent.verticalCenter
                    pixmaps: {
                        'default': root.imgPath+"stop.png",
                        'hovered': root.imgPath+"stop_h.png",

                    }
                    visible: !player.liveStream
                    onClicked: player.stop(false);
                }

                /* playlist button */
                Button {
                    id: btnPlaylist
                    anchors.verticalCenter: parent.verticalCenter
                    visible: player.hasPlaylist
                    pixmaps: {
                        'default': root.imgPath+"playlist.png",
                        'hovered': root.imgPath+"playlist_h.png"
                    }
                    onClicked: player.togglePlaylist();
                }

                /* previous+play+next buttons */
                Row {
                    id: play_prev_next_row
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.floor(parent.height * 0.225)

                    /* previous button */
                    Button {
                        id: btnPreviuos
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !player.liveStream && player.hasPlaylist
                        pixmaps: {
                            'default': root.imgPath+"prev.png",
                            'hovered': root.imgPath+"prev_h.png"
                        }
                        onClicked: player.prev()
                    }

                    /* play button */
                    DoubleStateButton {
                        id: btnPlay
                        anchors.verticalCenter: parent.verticalCenter
                        pixmaps: {
                            'default1': root.imgPath+"play.png",
                            'hovered1': root.imgPath+"play_h.png",
                            'default2': root.imgPath+"pause.png",
                            'hovered2': root.imgPath+"pause_h.png"
                        }

                        condition: player.state==playerstates.playing || player.state==playerstates.prebuffering
                        onClicked: player.play();
                    }

                    /* next button */
                    Button {
                        id: btnNext
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !player.liveStream && player.hasPlaylist
                        pixmaps: {
                            'default': root.imgPath+"next.png",
                            'hovered': root.imgPath+"next_h.png"
                        }
                        onClicked: player.next()
                    }
                }

                /* volume controls */
                Row {
                    id: volume_row
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.floor(parent.height * 0.4)

                    /* mute button */
                    DoubleStateButton {
                        id: btnMute
                        anchors.verticalCenter: parent.verticalCenter
                        pixmaps: {
                            'default1': root.imgPath+"mute-on.png",
                            'hovered1': root.imgPath+"mute-on_h.png",
                            'default2': root.imgPath+"mute-off.png",
                            'hovered2': root.imgPath+"mute-off_h.png"
                        }
                        condition: player.mute
                        onClicked: player.toggleMute()
                    }

                    /* volume down button */
                    Button {
                        id: btnVolDown
                        anchors.verticalCenter: parent.verticalCenter
                        pixmaps: {
                            'default': root.imgPath+"vol-down.png",
                            'hovered': root.imgPath+"vol-down_h.png"
                        }
                        onClicked: {
                            if(player.volume > 0)
                                player.changeVolume(player.volume-1)
                        }
                        onPressed: timerVolumeDown.running=true
                        onReleased: timerVolumeDown.running=false
                        Timer {
                            id: timerVolumeDown
                            interval: 100;
                            running: false
                            repeat: true
                            onTriggered: {
                                if(player.volume > 0)
                                    player.changeVolume(player.volume-1)
                            }
                        }
                    }

                    /* volume scale */
                    Image {
                        id: volumeScale
                        width: Math.floor(height * 5.5385)
                        anchors.verticalCenter: parent.verticalCenter
                        source: root.imgPath+"sound.png"

                        Text {
                            x: -parent.height*0.7
                            y: -parent.height*0.9
                            text: "volume"
                            color: "#cccccc"
                            font.pixelSize: Math.floor(parent.height * 0.6154)
                            smooth: true
                        }

                        /* volume label */
                        Text {
                            id: lblVolume
                            y: -parent.height*0.9
                            anchors.right: parent.right
                            anchors.rightMargin: -parent.height * 0.5
                            text: player.volume + "%"
                            color: soundLevelRed.visible ? soundLevelRed.color : soundLevelYellow.visible ? soundLevelYellow.color : soundLevelBlue.color
                            font.pixelSize: Math.floor(parent.height * 0.6154)
                            smooth: true
                        }

                        Item {
                            id: soundLevel
                            x: 0
                            y: (parent.height - height) / 2
                            width: parent.width
                            height: parent.height * 0.3846

                            /* blue */
                            Rectangle {
                                id: soundLevelBlue
                                x: 0
                                width: player.volume * parent.width / 100
                                height: parent.height
                                color: "#00a691"
                            }
                            /* yellow */
                            Rectangle {
                                id: soundLevelYellow
                                x: parent.width * 0.58
                                width: (player.volume - 58) * parent.width / 100
                                height: parent.height
                                color: "#dd9a22"
                                visible: player.volume > 58
                            }
                            /* red */
                            Rectangle {
                                id: soundLevelRed
                                x: parent.width * 0.76
                                width: (player.volume - 76) * parent.width / 100
                                height: parent.height
                                color: "#d73e3e"
                                visible: player.volume > 76
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var newVolume = parseInt(100 * mouseX / volumeScale.width);
                                player.changeVolume(newVolume);
                            }
                        }

                        /* slider */
                        Rectangle {
                            id: volumeSlider
                            x: volumeSliderArea.drag.active ? x : player.volume * volumeScale.width / 100 - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: Math.floor(parent.height*0.8462)
                            color: "#f8f8f8"

                            MouseArea {
                                id: volumeSliderArea
                                anchors.fill: parent
                                drag.target: parent
                                drag.axis: Drag.XAxis
                                drag.minimumX: 0 - volumeSlider.width / 2
                                drag.maximumX: volumeScale.width - volumeSlider.width / 2

                                onPositionChanged: {
                                    var newVolume = parseInt(100 * (volumeSlider.x + volumeSlider.width / 2) / volumeScale.width)
                                    player.changeVolume(newVolume);
                                }
                            }
                        }
                    }

                    /* volume up button */
                    Button {
                        id: btnVolUp
                        anchors.verticalCenter: parent.verticalCenter
                        pixmaps: {
                            'default': root.imgPath+"vol-up.png",
                            'hovered': root.imgPath+"vol-up_h.png"
                        }
                        //tooltip: "Volume up"

                        onClicked: {
                            if(player.volume < 100)
                                player.changeVolume(player.volume+1);
                        }
                        onPressed: timerVolumeUp.running=true
                        onReleased: timerVolumeUp.running=false
                        Timer {
                            id: timerVolumeUp
                            interval: 100;
                            running: false
                            repeat: true
                            onTriggered: {
                                if(player.volume < 100)
                                    player.changeVolume(player.volume+1);
                            }
                        }
                    }
                }

                /* Live */
                Item {
                    id: live_area
                    height: Math.floor(centralArea.height * 0.208)
                    width: live_txt.width + live_txt.x + live_img.x //Math.floor(height * 3)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: player.liveStream
                    
                    Rectangle {
                        color: "transparent"
                        border.color: "#e6e6e6"
                        border.width: 2
                        anchors.fill: parent
                    }
                    
                    Image {
                        id: live_img
                        height: Math.floor(parent.height * 0.467)
                        width: height
                        anchors.verticalCenter: parent.verticalCenter
                        x: height
                        
                        states: [
                            State {
                                name: "undefined"
                                when: player.liveStreamIsLive == -1
                                PropertyChanges { target: live_img; source: root.imgPath+"live_no_fs.png" }
                            },
                            State {
                                name: "timeshiftable"
                                when: player.liveStreamIsLive == 0
                                PropertyChanges { target: live_img; source: root.imgPath+"live_time.png" }
                            },
                            State {
                                name: "untimeshiftable"
                                when: player.liveStreamIsLive == 1
                                PropertyChanges { target: live_img; source: root.imgPath+"live.png" }
                            }
                        ]
                    }

                    Text {
                        id: live_txt
                        text: root.translate("Live")
                        color: "#e6e6e6"
                        font.pixelSize: live_img.height
                        anchors.verticalCenter: parent.verticalCenter
                        x: live_img.width + live_img.x*2.2
                    }
                    
                    MouseArea {
                        id: live_area_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true
                        //onEntered: standardToolTip.showToolTip(live_area.mapToItem(null, mouseX, mouseY).x, live_area.mapToItem(null, mouseX, mouseY).y, "Skip ahead to live broadcast")
                        //onExited: standardToolTip.hideToolTip()

                        CursorShapeArea {
                            anchors.fill: parent
                            cursorShape: live_img.state == "timeshiftable" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }

                        /*
                        StandardToolTipObject {
                            id: standardToolTip
                        }
                        */
                        
                        onClicked: {
                            if(live_img.state == "timeshiftable")
                                 player.changePlayback(-1);
                        }
                    }
                }

                /* Quality */
                Item {
                    id: quality_area
                    height: Math.floor(centralArea.height * 0.208)
                    width: quality_txt.width + live_txt.x
                    anchors.verticalCenter: parent.verticalCenter
                    visible: panel.hasQualityList

                    Rectangle {
                        color: "transparent"
                        border.color: "#e6e6e6"
                        border.width: 2
                        anchors.fill: parent
                    }


                    Text {
                        id: quality_txt
                        text: panel.hasQualityList ? panel.qualities[player.currentQuality] : ""
                        color: "#e6e6e6"
                        font.pixelSize: live_img.height
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: quality_area_mouse_area
                        anchors.fill: parent
                        hoverEnabled: true

                        CursorShapeArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }

                        onClicked: {
                            if(chooseQuality.visible)
                                panel.uninitQualityMenu()
                            else
                                panel.initQualityMenu()
                        }
                    }
                }
                
                /* save current button */
                Button {
                    id: btnSaveCurrent
                    anchors.verticalCenter: parent.verticalCenter
                    visible: player.saveable
                    pixmaps: {
                        'default': root.imgPath+"save.png",
                        'hovered': root.imgPath+"save_h.png"
                    }
                    onClicked: player.saveCurrent();
                }

                /* fullscreen button */
                Button {
                    id: btnFullscreen
                    anchors.verticalCenter: parent.verticalCenter
                    pixmaps: {
                        'default': root.imgPath+"fullscreen.png",
                        'hovered': root.imgPath+"fullscreen_h.png"
                    }
                    onClicked: player.toggleFullscreen();
                }

                /* power button */
                Button {
                    id: btnPower
                    anchors.verticalCenter: parent.verticalCenter
                    pixmaps: {
                        'default': root.imgPath+"power.png",
                        'hovered': root.imgPath+"power_h.png"
                    }
                    onClicked: player.stop(true);
                }
            }

            /* playback/duration label */
            Row {
                x: panel.width - width - Math.floor(panel.height * 0.1042)
                y: Math.floor(panel.height * 0.099)
                visible: !player.liveStream

                Text {
                    id: lblPlayback
                    text: Lib.secondsAsString(parseInt(player.duration * player.playback))
                    font.pixelSize: Math.floor(panel.height*0.1042)
                    color: "#e5e5e5"
                    smooth: true
                }
                Text {
                    text: "/"
                    font.pixelSize: lblPlayback.font.pixelSize
                    color: "#e5e5e5"
                    smooth: true
                }
                Text {
                    id: lblDuration
                    text: Lib.secondsAsString(player.duration)
                    font.pixelSize: lblPlayback.font.pixelSize
                    color: "#e5e5e5"
                    smooth: true
                }
            }

            /* choose quality */
            Item {
                id: chooseQuality
                width: Math.floor(centralArea.height * 0.9583)
                height: qBottom.height + qMiddle.height + qTop.height - chooseQuality.rowSpacing //Math.floor(width * 1.057971) //146
                y: buttons_row.y - height
                x: buttons_row.x + quality_area.x + quality_area.width / 2 - width / 2
                smooth: true
                visible: false

                property int rowHeight : Math.floor(chooseQuality.width * 0.130435)
                property int rowWidth : Math.floor(chooseQuality.width * 0.826087)
                property int rowSpacing : Math.floor(chooseQuality.width * 0.039855)

                property int spacing : Math.floor(chooseQuality.width * 0.123188)
                property int itemsCount : 5

                Image {
                    id: qTop
                    source: root.imgPath + "q-top.png"
                    width: parent.width
                    anchors.bottom: qMiddle.top
                    opacity: 0.9
                }
                Image {
                    id: qMiddle
                    source: root.imgPath + "q-middle.png"
                    width: parent.width
                    height: qList.height + qTitle.height + 2 * chooseQuality.spacing //chooseQuality.height - qTop.height - qBottom.height
                    anchors.bottom: qBottom.top //y: qTop.height
                    fillMode: Image.TileVertically
                    opacity: 0.9
                }
                Image {
                    id: qBottom
                    source: root.imgPath + "q-bottom.png"
                    width: parent.width
                    anchors.bottom: parent.bottom
                    opacity: 0.9
                }

                Rectangle {
                    id: qTitle
                    color: "#2f2f2f"
                    height: chooseQuality.rowHeight
                    width: chooseQuality.rowWidth
                    y: Math.floor(chooseQuality.width * 0.043478)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        id: qTitleText
                        text: root.translate("Quality")
                        color: "#d5d5d5"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    id: qList
                    width: chooseQuality.rowWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: qTitle.y + qTitle.height + chooseQuality.spacing
                    spacing: chooseQuality.rowSpacing

                    Rectangle {
                        color: index == player.currentQuality ? "#d6d6d5" : hovered ? "#656565" : "transparent"
                        height: chooseQuality.rowHeight
                        width: parent.width
                        visible: false
                        property string name: "";
                        property string bitrate: "";
                        property int index: 0;
                        property bool hovered: false

                        Text {
                            text: parent.name + " " + parent.bitrate
                            color: parent.index == player.currentQuality ? "#2b2b2b" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: parent.hovered = true;
                            onExited: parent.hovered = false;
                            onClicked: {
                                if(parent.index != player.currentQuality)
                                    player.changeQuality(parent.index);
                                panel.uninitQualityMenu();
                            }
                        }
                    }

                    Rectangle {
                        color: index == player.currentQuality ? "#d6d6d5" : hovered ? "#656565" : "transparent"
                        height: chooseQuality.rowHeight
                        width: parent.width
                        visible: false
                        property string name: "";
                        property string bitrate: "";
                        property int index: 1;
                        property bool hovered: false

                        Text {
                            text: parent.name + " " + parent.bitrate
                            color: parent.index == player.currentQuality ? "#2b2b2b" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: parent.hovered = true;
                            onExited: parent.hovered = false;
                            onClicked: {
                                if(parent.index != player.currentQuality)
                                    player.changeQuality(parent.index);
                                panel.uninitQualityMenu();
                            }
                        }
                    }

                    Rectangle {
                        color: index == player.currentQuality ? "#d6d6d5" : hovered ? "#656565" : "transparent"
                        height: chooseQuality.rowHeight
                        width: parent.width
                        visible: false
                        property string name: "";
                        property string bitrate: "";
                        property int index: 2;
                        property bool hovered: false

                        Text {
                            text: parent.name + " " + parent.bitrate
                            color: parent.index == player.currentQuality ? "#2b2b2b" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: parent.hovered = true;
                            onExited: parent.hovered = false;
                            onClicked: {
                                if(parent.index != player.currentQuality)
                                    player.changeQuality(parent.index);
                                panel.uninitQualityMenu();
                            }
                        }
                    }

                    Rectangle {
                        color: index == player.currentQuality ? "#d6d6d5" : hovered ? "#656565" : "transparent"
                        height: chooseQuality.rowHeight
                        width: parent.width
                        visible: false
                        property string name: "";
                        property string bitrate: "";
                        property int index: 3;
                        property bool hovered: false

                        Text {
                            text: parent.name + " " + parent.bitrate
                            color: parent.index == player.currentQuality ? "#2b2b2b" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: parent.hovered = true;
                            onExited: parent.hovered = false;
                            onClicked: {
                                if(parent.index != player.currentQuality)
                                    player.changeQuality(parent.index);
                                panel.uninitQualityMenu();
                            }
                        }
                    }

                    Rectangle {
                        color: index == player.currentQuality ? "#d6d6d5" : hovered ? "#656565" : "transparent"
                        height: chooseQuality.rowHeight
                        width: parent.width
                        visible: false
                        property string name: "";
                        property string bitrate: "";
                        property int index: 4;
                        property bool hovered: false

                        Text {
                            text: parent.name + " " + parent.bitrate
                            color: parent.index == player.currentQuality ? "#2b2b2b" : "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: parent.hovered = true;
                            onExited: parent.hovered = false;
                            onClicked: {
                                if(parent.index != player.currentQuality)
                                    player.changeQuality(parent.index);
                                panel.uninitQualityMenu();
                            }
                        }
                    }
                }
            }
        }

        /* bottom panel area */
        Rectangle {
            id: bottomArea
            width: parent.width
            height: Math.floor(panel.height*0.1875)
            visible: !player.minPanel && !player.hasInteractive
            color: "#444444"
            opacity: 0.45

            Row {
                Image {
                    id: bmPlay
                    width: bottomArea.height * 1.97
                    height: bottomArea.height
                    source: root.imgPath + "bm-play-active.png"
                    smooth: true
                }

                Rectangle {
                    width: bottomArea.width - bmPlay.width
                    height: bottomArea.height
                    color: "#2f2f2f"
                }
            }
        }

        /* minimal panel */
        PanelMinimal {
            id: panelMinimal
            width: panel.width
            height: panel.height - playbackProgressBar.height
            visible: player.minPanel || player.hasInteractive
        }
    }

    /* tip */
    Item {
        id: tip_area
        width: lblTip.width+height //Math.floor(height * 5.033)
        height: Math.floor(centralArea.height * 0.208)
        y: playbackProgressBar.height + playbackProgressBar.height*1.4
        x: {
            var new_x = 0;
            if(live_area_mouse_area.containsMouse) {
                new_x = buttons_row.x + live_area.x + live_area.width / 2;
            }
            else if(btnPlay.containsMouse) {
                new_x = buttons_row.x + play_prev_next_row.x + btnPlay.x + btnPlay.width / 2;
            }
            else if(btnStop.containsMouse) {
                new_x = buttons_row.x + btnStop.x + btnStop.width / 2;
            }
            else if(btnSaveCurrent.containsMouse) {
                new_x = buttons_row.x + btnSaveCurrent.x + btnSaveCurrent.width / 2;
            }
            else if(btnPlaylist.containsMouse) {
                new_x = buttons_row.x + btnPlaylist.x + btnPlaylist.width / 2;
            }
            else if(btnFullscreen.containsMouse) {
                new_x = buttons_row.x + btnFullscreen.x + btnFullscreen.width / 2;
            }
            else if(btnPower.containsMouse) {
                new_x = buttons_row.x + btnPower.x + btnPower.width / 2;
            }
            else if(btnMute.containsMouse) {
                new_x = buttons_row.x + volume_row.x + btnMute.x + btnMute.width / 2;
            }
            else if(btnVolDown.containsMouse) {
                new_x = buttons_row.x + volume_row.x + btnVolDown.x + btnVolDown.width / 2;
            }
            else if(btnVolUp.containsMouse) {
                new_x = buttons_row.x + volume_row.x + btnVolUp.x + btnVolUp.width / 2;
            }
            
            if(new_x == 0) {
                new_x = last_x;
            }
            else {
                last_x = new_x;
            }
            
            return new_x;
        }
        opacity: 0
        smooth: true
        property int last_x: 0
        property string last_text: ""

        Image {
            id: tip_start
            height:  parent.height
            width: height
            source: root.imgPath + "tip-start.png"
        }
        Image {
            id: tip_body
            height: parent.height
            width: parent.width - tip_start.width
            x: tip_start.width
            source: root.imgPath + "tip-body.png"
            fillMode: Image.TileHorizontally
        }

        states: [
             State { name: "show_tip";
                 when: (live_area_mouse_area.containsMouse && live_img.state != "undefined")
                       || btnStop.containsMouse
                       || btnPlaylist.containsMouse
                       || btnPlay.containsMouse
                       || btnSaveCurrent.containsMouse
                       || btnFullscreen.containsMouse
                       || btnPower.containsMouse
                       || btnMute.containsMouse
                       || btnVolDown.containsMouse
                       || btnVolUp.containsMouse
                       },
             State { name: "hide_tip";
                 when: !(live_area_mouse_area.containsMouse && live_img.state != "undefined")
                       && !btnStop.containsMouse
                       && !btnPlaylist.containsMouse
                       && !btnPlay.containsMouse
                       && !btnSaveCurrent.containsMouse
                       && !btnFullscreen.containsMouse
                       && !btnPower.containsMouse
                       && !btnMute.containsMouse
                       && !btnVolDown.containsMouse
                       && !btnVolUp.containsMouse
                       }
         ]
        transitions: [
         Transition {
             from: "hide_tip"; to: "show_tip"
             NumberAnimation {
                 target: tip_area
                 properties: "opacity"
                 from: 0; to: 1; duration: 500
             }
         },
         Transition {
             from: "show_tip"; to: "hide_tip"
             NumberAnimation {
                 target: tip_area
                 properties: "opacity"
                 from: 1; to: 0; duration: 500
             }
         }
        ]

        Text {
            id: lblTip
            y: (parent.height - height - 6) / 2
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 11
            color: "#e6e6e6"
            text: {
                var new_text = "";
                if(live_area_mouse_area.containsMouse) {
                    if(live_img.state == "untimeshiftable") {
                        new_text = "You are watching live broadcast";
                    }
                    else {
                        new_text = "Skip ahead to live broadcast";
                    }
                }
                else if(btnPlay.containsMouse) {
                    new_text = btnPlay.condition ? "Pause" : "Play";
                }
                else if(btnSaveCurrent.containsMouse) {
                    new_text = "Save";
                }
                else if(btnPlaylist.containsMouse) {
                    new_text = "Playlist";
                }
                else if(btnFullscreen.containsMouse) {
                    new_text = "Exit Fullscreen";
                }
                else if(btnPower.containsMouse) {
                    new_text = "Turn off";
                }
                else if(btnStop.containsMouse) {
                    new_text = "Stop";
                }
                else if(btnMute.containsMouse) {
                    new_text = btnMute.condition ? "Mute off" : "Mute on";
                }
                else if(btnVolDown.containsMouse) {
                    new_text = "Volume down";
                }
                else if(btnVolUp.containsMouse) {
                    new_text = "Volume up";
                }
                
                if(new_text.length == 0) {
                    new_text = parent.last_text;
                }
                else {
                    parent.last_text = new_text;
                }
                
                if(new_text.length == 0) {
                    return "";
                }
                
                return root.translate(new_text);
            }
        }
    }
}
