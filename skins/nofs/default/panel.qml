import QtQuick 1.1
import "functions.js" as Lib
import CursorShape 1.0
import Translator 1.0
import StandardToolTip 1.0

/* panel.qml */
/* background image */
Image {
    id: root
    width: 600
    height: 36
    source: "panel/bg.png"
    fillMode: Image.TileHorizontally
    smooth: true
 
    property bool hasQualityList: qualities != 0 && qualities.length > 0
    property variant qualities: 0
    property variant bitrates: 0
    function qualitiesChanged(val1, val2) { if(val1 == "") return; root.qualities=val1.split("|"); root.bitrates=val2.split("|"); }
    
    /* menu quality functions */
    function qualityButtonWidth() {
        var q = root.qualities;
        q.sort(root.sortFunction);
        var max_str = q[0]
        var newObject = Qt.createQmlObject('import QtQuick 1.0;' +
            'Text {text: "'+max_str+'"; visible:false; font.pixelSize: 12}', root);
        var width_q = newObject.width;
        newObject.destroy();

        var b = root.bitrates;
        b.sort(root.sortFunction);
        max_str = b[0]
        var newObject1 = Qt.createQmlObject('import QtQuick 1.0;' +
            'Text {text: "'+max_str+'"; visible:false; font.pixelSize: 8}', root);
        var width_b = newObject1.width;
        newObject1.destroy();

        var width = width_q > width_b ? width_q : width_b
        return width + 10;
    }

    function sortFunction(a, b) {
        if(a.length > b.length)
            return -1;
        if(a.length < b.lenght)
            return 1;
        return 0;
    }

    function initQualityMenu() {
        var itemWidth = root.qualityButtonWidth();
        for(var i = 0; i < root.qualities.length && i < rowQuality.children.length; i++) {
            rowQuality.children[i].width = itemWidth;
            rowQuality.children[i].name = root.qualities[i];
            rowQuality.children[i].bitrate =root.bitrates[i];
            rowQuality.children[i].hovered = false;
            rowQuality.children[i].visible = true;
        }
        menuQuality.visible = true;
    }

    function uninitQualityMenu() {
        menuQuality.visible = false;
        for(var i = 0; i < menuQuality.itemsCount; i++) {
            rowQuality.children[i].hovered = false;
            rowQuality.children[i].visible = false;
        }
    }

    /* translator */
    TranslatorObject {
        id: translator
    }
    function translate(val) { return translator.translate(val); }
    
    Item {
        id: playerstates
        property int playing: 0
        property int paused: 1
        property int prebuffering: 2
        property int stopped: 3
        property int fullstopped: 4
    }
    
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: player.changeCanHide(false);
        onExited: player.changeCanHide(true); 
    
        /* panel view */
        Column {
            id: panelMainLayout
            anchors.fill: parent
            spacing: 0

            /* playback progress bar */
            Rectangle {
                id: playbackProgressBar
                height: 8
                anchors.left: parent.left
                anchors.right: parent.right
                color: "#676767"

                MouseArea {
                    id: playbackProgressBarArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if( player.state >= playerstates.stopped ) return;
                        var newPlayback = mouseX / playbackProgressBar.width;
                        if( player.liveStream )
                            player.statusMsg = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                        else
                            player.statusMsg = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                        player.changePlayback(newPlayback);
                    }
                    onMousePositionChanged: {
                        if( player.state >= playerstates.stopped ) return;
                        var newPlayback = mouseX / playbackProgressBar.width;
                        if( player.liveStream )
                            player.statusMsg = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                        else
                            player.statusMsg = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                    }
                    onExited: player.statusMsg = ""

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
                            drag.maximumX: ( player.state >= playerstates.stopped ) ? drag.minimumX : playbackProgressBar.width - playbackProgressBarSlider.width / 2

                            onPositionChanged: {
                                if( player.state >= playerstates.stopped ) return;
                                var newPlayback = (playbackProgressBarSlider.x + playbackProgressBarSlider.width / 2) / playbackProgressBar.width;
                                if( player.liveStream )
                                    player.statusMsg = "-" + Lib.secondsAsString(parseInt(player.duration - player.duration * newPlayback));
                                else
                                    player.statusMsg = Lib.secondsAsString(parseInt(player.duration * newPlayback));
                            }

                            onReleased: {
                                if( player.state >= playerstates.stopped ) return;
                                var newPlayback = (playbackProgressBarSlider.x + playbackProgressBarSlider.width / 2) / playbackProgressBar.width;
                                player.changedPlayback(newPlayback);
                            }
                        }
                    }
                }
            }

            /* panel controls */
            Item {
                id: panel
                height: root.height - playbackProgressBar.height
                anchors.left: parent.left
                anchors.right: parent.right

                /* qualities menu */
                MouseArea {
                    id: menuQuality
                    hoverEnabled: true
                    z: 5
                    anchors.right: parent.right
                    anchors.rightMargin: rowQuality.width
                        + (btnPower.visible ? (btnPower.width+1) : 0)
                        + (btnFullscreen.visible ? (btnFullscreen.width+1) : 0)
                        + (btnPlaylist.visible ? (btnPlaylist.width+1) : 0)
                        + (btnSaveCurrent.visible ? (btnSaveCurrent.width+1) : 0)
                    height: panel.height
                    visible: false
                    onExited: root.uninitQualityMenu()
                    property int itemsCount: 5

                    Row {
                        id: rowQuality
                        height: parent.height
                        
                        Image {
                            width: 0
                            visible: false
                            height: panel.height;
                            source: "panel/bg.png";
                            property string name: "";
                            property string bitrate: "";
                            property int index: 0;
                            property bool hovered: false
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#404040"
                                anchors.left: parent.left
                            }

                            Text {
                                text: parent.name
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 12
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: parent.bitrate
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    root.uninitQualityMenu();
                                    if(parent.index != player.currentQuality)
                                        player.changeQuality(parent.index);
                                }
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                CursorShapeArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }

                                StandardToolTipObject {
                                    anchors.fill: parent
                                    text: parent.name
                                }
                            }
                        }

                        Image {
                            width: 0
                            visible: false
                            height: panel.height;
                            source: "panel/bg.png";
                            property string name: "";
                            property string bitrate: "";
                            property int index: 1;
                            property bool hovered: false
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#404040"
                                anchors.left: parent.left
                            }

                            Text {
                                text: parent.name
                                color: parent.index == player.currentQuality? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 12
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: parent.bitrate
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    root.uninitQualityMenu();
                                    if(parent.index != player.currentQuality)
                                        player.changeQuality(parent.index);
                                }
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                CursorShapeArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }

                                StandardToolTipObject {
                                    anchors.fill: parent
                                    text: parent.name
                                }
                            }
                        }

                        Image {
                            width: 0
                            visible: false
                            height: panel.height;
                            source: "panel/bg.png";
                            property string name: "";
                            property string bitrate: "";
                            property int index: 2;
                            property bool hovered: false
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#404040"
                                anchors.left: parent.left
                            }

                            Text {
                                text: parent.name
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 12
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: parent.bitrate
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    root.uninitQualityMenu();
                                    if(parent.index != player.currentQuality)
                                        player.changeQuality(parent.index);
                                }
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                CursorShapeArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }

                                StandardToolTipObject {
                                    anchors.fill: parent
                                    text: parent.name
                                }
                            }
                        }

                        Image {
                            width: 0
                            visible: false
                            height: panel.height;
                            source: "panel/bg.png";
                            property string name: "";
                            property string bitrate: "";
                            property int index: 3;
                            property bool hovered: false
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#404040"
                                anchors.left: parent.left
                            }

                            Text {
                                text: parent.name
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 12
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: parent.bitrate
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    root.uninitQualityMenu();
                                    if(parent.index != player.currentQuality)
                                        player.changeQuality(parent.index);
                                }
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                CursorShapeArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }

                                StandardToolTipObject {
                                    anchors.fill: parent
                                    text: parent.name
                                }
                            }
                        }

                        Image {
                            width: 0
                            visible: false
                            height: panel.height;
                            source: "panel/bg.png";
                            property string name: "";
                            property string bitrate: "";
                            property int index: 4;
                            property bool hovered: false
                            
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: "#404040"
                                anchors.left: parent.left
                            }

                            Text {
                                text: parent.name
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 12
                                anchors.top: parent.top
                                anchors.topMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: parent.bitrate
                                color: parent.index == player.currentQuality ? "#00a691" : parent.hovered ? "#ffffff" : "#909090"
                                font.pixelSize: 8
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            MouseArea {
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    root.uninitQualityMenu();
                                    if(parent.index != player.currentQuality)
                                        player.changeQuality(parent.index);
                                }
                                onEntered: parent.hovered = true
                                onExited: parent.hovered = false
                                CursorShapeArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                }

                                StandardToolTipObject {
                                    anchors.fill: parent
                                    text: parent.name
                                }
                            }
                        }
                    }
                }

                /* left side buttons layout */
                Row {
                    id: leftRow
                    spacing: 0

                    /* skip ad button */
                    Item {
                        id: btnAd
                        width: state == "skip" ? lblAd.width + 10 + parent.height : lblSkip.width + 10
                        height: parent.height
                        visible: player.isAd
                 
                        states: [
                            State {
                                name: "skip"
                                when: player.waitForAd >= -2
                                PropertyChanges {
                                    target: skip_layout
                                    visible: true
                                    onVisibleChanged: { player.skipAd(); }
                                    Component.onCompleted: { player.skipAd(); }
                                }
                            }
                        ]

                        MouseArea {
                            id: skip_layout
                            anchors.fill: parent
                            hoverEnabled: true
                            visible: false

                            onEntered: player.skipAd();

                            Text {
                                id: lblSkip
                                text: translator.translate("Skip")
                                color: skip_layout.containsMouse ? "#D5D5D5" : "#E5E5E5"
                                font.pixelSize: 18
                                anchors.centerIn: parent
                            }

                            CursorShapeArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        
                    }

                    /* prev buttton */
                    Button {
                        id: btnPrev
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !player.liveStream && player.hasPlaylist
                        pixmaps: {
                            'default': "panel/prev.png",
                            'hovered': "panel/prev_h.png"
                        }
                        tooltip: "Previous"
                        onClicked: player.prev()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnPrev.visible
                    }

                    /* play button */
                    DoubleStateButton {
                        id: btnPlay
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter
                        pixmaps: {
                            'default1': "panel/play-btn.png",
                            'hovered1': "panel/play-btn_h.png",
                            'default2': "panel/pause-btn.png",
                            'hovered2': "panel/pause-btn_h.png"
                        }
                        tooltips: {
                            '1': "Play",
                            '2': "Pause"
                        }
                        visible: true

                        condition: player.state == playerstates.playing || player.state == playerstates.prebuffering
                        Component.onCompleted: { player.skipAd(); }
                        onClicked: player.play()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnPlay.visible
                    }

                    /* next button */
                    Button {
                        id: btnNext
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !player.liveStream && player.hasPlaylist
                        pixmaps: {
                            'default': "panel/next.png",
                            'hovered': "panel/next_h.png"
                        }
                        tooltip: "Next"
                        onClicked: player.next()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnNext.visible
                    }
                    
                    /* Live */
                    Item {
                        id: live_options
                        width: live_name.width+live_name.x+live_img.x*2 //56
                        height: parent.height
                        y: 0
                        x: volume_holder.x + volume_holder.width
                        visible: player.liveStream

                        Image {
                            id: live_img
                            width: 10
                            height: 10
                            x: 9
                            y: 8
                            smooth: true
                            
                            states: [
                                State {
                                    name: "undefined"
                                    when: player.liveStreamIsLive == -1
                                    PropertyChanges { target: live_img; source: "panel/live_no.png" }
                                },
                                State {
                                    name: "timeshiftable"
                                    when: player.liveStreamIsLive == 0
                                    PropertyChanges { target: live_img; source: "panel/live_time.png" }
                                },
                                State {
                                    name: "untimeshiftable"
                                    when: player.liveStreamIsLive == 1
                                    PropertyChanges { target: live_img; source: "panel/live.png" }
                                }
                            ]
                            
                            Text {
                                id: live_name
                                text: root.translate("Live")
                                color: "#909090"
                                font.pixelSize: 12
                                x: parent.width + 7
                                y: -2
                            }
                        }

                        MouseArea {
                            id: live_area
                            anchors.fill: parent
                            
                            CursorShapeArea {
                                anchors.fill: parent
                                cursorShape: live_img.state == "timeshiftable" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }

                            StandardToolTipObject {
                                anchors.fill: parent
                                text: {
                                    if(live_img.state == "untimeshiftable") {
                                        return "You are watching live broadcast";
                                    }
                                    else {
                                        return "Skip ahead to live broadcast";
                                    }
                                }
                            }
                            
                            onClicked: if( live_img.state == "timeshiftable" ) player.changePlayback(-1)
                        }
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: live_options.visible
                    }

                    /* volume controls */
                    Item {
                        id: volumeHolder
                        width:  volumeControlsRow.width
                        height: panel.height

                        MouseArea {
                            id: volumeHolderArea
                            anchors.fill: parent
                            hoverEnabled: true

                            Row {
                                id: volumeControlsRow
                                spacing: 0

                                /* mute button */
                                DoubleStateButton {
                                    id: btnMute
                                    width: 33
                                    height: panel.height
                                    anchors.verticalCenter: parent.verticalCenter
                                    pixmaps: {
                                        'default1': "panel/mute-btn-on.png",
                                        'hovered1': "panel/mute-btn-on_h.png",
                                        'default2': "panel/mute-btn-off.png",
                                        'hovered2': "panel/mute-btn-off_h.png"
                                    }
                                    condition: player.mute
                                    tooltips: {
                                         '1': "Mute on",
                                         '2': "Mute off"
                                    }
                                    onClicked: player.toggleMute()
                                }

                                Row {
                                    spacing: 10

                                    /* volume scale */
                                    Item {
                                        id: volumeScaleHolder
                                        width: 108
                                        height: panel.height
                                        visible: volumeHolderArea.containsMouse

                                        Image {
                                            id: volumeScale
                                            width: parent.width
                                            height: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            source: "panel/scale.png"

                                            Rectangle {
                                                id: soundLevel
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                height: 4
                                                color: "#404040"

                                                Rectangle {
                                                    x: 0
                                                    width: player.volume * parent.width / 100
                                                    height: parent.height
                                                    color: "#00a691"
                                                }
                                                Rectangle {
                                                    x: parent.width * 0.58
                                                    width: (player.volume - 58) * parent.width / 100
                                                    height: parent.height
                                                    color: "#dd9a22"
                                                    visible: player.volume > 58
                                                }
                                                Rectangle {
                                                    x: parent.width * 0.76
                                                    width: (player.volume - 76) * parent.width / 100
                                                    height: parent.height
                                                    color: "#d73e3e"
                                                    visible: player.volume > 76
                                                }
                                            }

                                            MouseArea {
                                                id: volumeScaleArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    var newVolume = parseInt(100 * mouseX / volumeScale.width);
                                                    player.changeVolume(newVolume);
                                                }
                                                onMousePositionChanged: {
                                                    var newVolume = parseInt(100 * mouseX / volumeScale.width);
                                                    player.statusMsg = newVolume + "%";
                                                }
                                                onExited: player.statusMsg = ""
                                            }

                                            Rectangle {
                                                id: volumeSlider
                                                x: volumeSliderArea.drag.active ? x : player.volume * volumeScale.width / 100
                                                y: (parent.height - height) / 2
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
                                                        var newVolume = parseInt(100 * (volumeSlider.x + volumeSlider.width / 2) / volumeScale.width);
                                                        player.statusMsg = newVolume + "%";
                                                        player.changeVolume(newVolume);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    /* separator */
                                    Rectangle {
                                        width: 1
                                        height: panel.height
                                        color: "#404040"
                                        visible: btnMute.visible
                                    }
                                }
                            }
                        }
                    }

                    /* playback/duration label */
                    Item {
                        id: lblTimeValues
                        width: lblTimeLayout.width + 10
                        height: panel.height
                        visible: !player.liveStream && !volumeHolderArea.containsMouse

                        Row {
                            id: lblTimeLayout
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0

                            Text {
                                id: lblPlayback
                                text: Lib.secondsAsString(parseInt(player.duration * player.playback))
                                font.pixelSize: 11
                                color: "#e5e5e5"
                                smooth: true
                            }
                            Text {
                                text: "/"
                                font.pixelSize: 11
                                color: "#e5e5e5"
                                smooth: true
                            }
                            Text {
                                id: lblDuration
                                text: Lib.secondsAsString(player.duration)
                                font.pixelSize: 11
                                color: "#e5e5e5"
                                smooth: true
                            }
                        }
                    }
                }

                /* information label */
                Item {
                    id: lblInformationItem
                    height: panel.height
                    anchors.left: leftRow.right
                    anchors.leftMargin: 5
                    anchors.right: rightRow.left
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Text {
                        id: lblInfo
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 11
                        color: "#e5e5e5"
                        text: player.statusMsg == "" ? player.currentTitle : player.statusMsg
                        property bool animate:  lblInfo.width / lblInformationItem.width > 0.8

                        onTextChanged: {
                            animate = lblInfo.width / lblInformationItem.width > 0.8
                            if(animate) {
                                if(!animateInfo.running) {
                                    animateInfo.from = 0;
                                    animateInfo.to = -lblInfo.width;
                                    animateInfo.duration = 20000;
                                    animateInfo.start();
                                }
                            }
                            else {
                                animateInfo.stop();
                                lblInfo.x=0;
                            }
                        }

                        PropertyAnimation on x {
                            id: animateInfo
                            running: false
                            from: 0;
                            to: -lblInfo.width;
                            duration: 20000;
                            onRunningChanged: {
                                if(!running && lblInfo.animate ) {
                                    if( from === 0 ) {
                                        from = lblInformationItem.width;
                                        duration = duration * 1.5;
                                    }
                                    start()
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { if(lblInfo.animate) animateInfo.pause() }
                        onExited: { if(lblInfo.animate) animateInfo.resume() }
                    }
                }

                /* right side buttons layout */
                Row {
                    id: rightRow
                    anchors.right: parent.right
                    spacing: 0

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnQuality.visible
                    }

                    /* quality button */
                    Item {
                        id: btnQuality
                        visible: root.hasQualityList && !menuQuality.visible
                        width: Math.max(lblQuality.width, lblBitrate.width) + 10
                        height: panel.height

                        Text {
                            id: lblQuality
                            text: root.hasQualityList ? root.qualities[player.currentQuality] : ""
                            color: "#909090"
                            font.pixelSize: 12
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            id: lblBitrate
                            text: root.hasQualityList ? root.bitrates[player.currentQuality] : ""
                            color: "#909090"
                            font.pixelSize: 8
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.initQualityMenu()

                            CursorShapeArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }

                            StandardToolTipObject {
                                anchors.fill: parent
                                text: root.translate("Quality menu")
                            }
                        }
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnSaveCurrent.visible
                    }

                    /* save button */
                    Button {
                        id: btnSaveCurrent
                        width: 55
                        height: panel.height
                        visible: player.saveable
                        pixmaps: {
                            'default': "panel/save-btn.png",
                            'hovered': "panel/save-btn_h.png"
                        }
                        tooltip: "Save"
                        onClicked: player.saveCurrent()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnPlaylist.visible
                    }

                    /* playlist button */
                    DoubleStateButton {
                        id: btnPlaylist
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter
                        visible: player.hasPlaylist
                        pixmaps: {
                            'default1': "panel/playlist-btn.png",
                            'hovered1': "panel/playlist-btn_h.png",
                            'default2': "panel/playlist-active.png",
                            'hovered2': "panel/playlist-active.png"
                        }
                        condition: player.playlistVisible
                        tooltips: {
                            '1': "Playlist",
                            '2': "Playlist"
                        }

                        onClicked: player.togglePlaylist()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnFullscreen.visible
                    }

                    /* fullscreen button */
                    Button {
                        id: btnFullscreen
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter

                        pixmaps: {
                            'default': "panel/fullscreen-btn.png",
                            'hovered': "panel/fullscreen-btn_h.png"
                        }
                        tooltip: "Fullscreen"
                        onClicked: player.toggleFullscreen()
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        visible: btnPower.visible
                    }

                    /* power button */
                    DoubleStateButton {
                        id: btnPower
                        width: 55
                        height: panel.height
                        anchors.verticalCenter: parent.verticalCenter
                        visible: true

                        pixmaps: {
                            'default1': "panel/power-on.png",
                            'hovered1': "panel/power-on_h.png",
                            'default2': "panel/power-off.png",
                            'hovered2': "panel/power-off_h.png"
                        }
                        condition: player.state == playerstates.fullstopped
                        tooltips: {
                             '1': "Turn off",
                             '2': "Turn off"
                        }

                        onClicked: player.stop(true);
                    }

                    /* separator */
                    Rectangle {
                        width: 1
                        height: panel.height
                        color: "#404040"
                        
                    }

                    /* unable ads button */
                    Item {
                        
                        MouseArea {
                            
                            CursorShapeArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }

                            StandardToolTipObject {
                                anchors.fill: parent
                                text: root.translate("Do not display ads anymore")
                            }
                        }
                    }
                }
            }
        }
    }
}
