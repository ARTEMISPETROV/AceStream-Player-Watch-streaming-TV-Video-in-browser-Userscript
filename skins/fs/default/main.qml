import QtQuick 1.1
import "functions.js" as Lib
import Translator 1.0
import CursorShape 1.0
import StandardToolTip 1.0

/* main.qml */
MouseArea {
    id: root
    hoverEnabled: true

    property variant panelSize: Lib.getPanelSize(width, height)
    property variant playlistSize: Lib.getPlaylistSize(width)
    property string imgPath: Lib.getImagesPath(width)
    
    function playlistWheel(val) { playlist.wheel(val); }
    function controlsShow() { 
        if(animationHide.running) {
            animationHide.forced = true;
            animationHide.stop();
            panel.opacity = 1;
        }
        else
            animationHide.forced = false;
        if(!animationShow.running) 
            animationShow.start(); 
    }
    function controlsHide() { 
         if(animationShow.running)
            animationShow.stop();
        if(!animationHide.running)
            animationHide.start() 
    }
    function qualitiesChanged(val1, val2) { 
        if(val1 == "") 
            return; 
        panel.qualities=val1.split("|"); 
        panel.bitrates=val2.split("|"); 
    }
    
    onClicked: player.mousePress();                       // only for linux
    onPositionChanged: player.mouseMove(mouseX, mouseY);  // only for linux
    onDoubleClicked: player.mouseDoubleClick();         // only for linux
    onHeightChanged: player.setPanelHeight(player.minPanel ? 48 : Lib.getPanelSize(root.width, root.height).height);

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
    
    /* default/small panel switcher */
    DoubleStateButton {
        id: btnPanelSwitcher
        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottom: root.bottom
        anchors.bottomMargin: panel.height + Math.round(panel.width * 0.004)
        visible: !player.isAd && !player.hasInteractive
        pixmaps: {
            'default1': root.imgPath+"squeeze.png",
            'hovered1': root.imgPath+"squeeze_h.png",
            'default2': root.imgPath+"expand.png",
            'hovered2': root.imgPath+"expand_h.png"
        }
        condition: player.minPanel
        onClicked: { 
            player.togglePanelSize(!player.minPanel);
            player.setPanelHeight(player.minPanel ? 48 : Lib.getPanelSize(root.width, root.height).height);
        }
    }

    Rectangle {
        id: btnVisitAdSite
        anchors.horizontalCenter: root.horizontalCenter
        anchors.bottom: root.bottom
        anchors.bottomMargin: panel.height + Math.round(panel.width * 0.004)
        visible: player.isAd && player.visitAdText != ""
        width: lblVisit.width + 10
        height: 26
        color: "#444444"

        MouseArea {
            id: txt_layout
            anchors.fill: parent
            hoverEnabled: true

            onClicked: player.skipAd();

            Text {
                id: lblVisit
                text: player.visitAdText
                color: txt_layout.containsMouse ? "#D5D5D5" : "#E5E5E5"
                font.pixelSize: 12
                anchors.centerIn: parent
            }

            CursorShapeArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
            }
        }
         Component.onCompleted: { player.skipAd(); }
    }

    Rectangle {
        width: root.width
        height: 1
        color: "#000000"
        anchors.bottom: root.bottom
    }
    
    /* panel from Panel.qml */
    Panel {
        id: panel
        width: root.width
        height: player.minPanel || player.hasInteractive ? 48 : root.panelSize.height
        anchors.bottom: root.bottom

        onEntered: player.changeCanHide(false);
        onExited: player.changeCanHide(true);
        
        NumberAnimation {
            id: animationShow
            target: panel
            properties: "opacity"
            from: 0.0
            to: 1
            duration: 500
        }
        NumberAnimation {
            id: animationHide
            target: panel
            properties: "opacity"
            from: 1
            to: 0.0
            duration: 500
            property bool forced: false
            onRunningChanged: { 
                if(!running && !forced) 
                    player.controlsHidden(); 
                forced = false;
            }
        }
    }

    /* playlist from Playlist.qml */
    Playlist {
        id: playlist
        x: (root.width - width) / 2
        y: (root.height - panel.height - height) / 2
        width: root.playlistSize.width
        height: root.playlistSize.height
        visible: player.playlistVisible
    }
}

