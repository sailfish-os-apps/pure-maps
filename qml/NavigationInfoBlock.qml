/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2014 Osmo Salomaa
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: block
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    color: "#e6000000"
    height: Theme.paddingSmall + speed.height

//    {

//        if (!destDist) return 0;
//        var h1 = iconImage.height + 2 * Theme.paddingLarge;
//        var h2 = manLabel.height + Theme.paddingSmall + narrativeLabel.height;
//        // If far off route, manLabel defines the height of the block,
//        // but we need padding to make a sufficiently large tap target.
//        var h3 = 1.3 * manLabel.height;
//        return Math.max(h1, h2, h3);
//    }

    z: 500

    property string destDist:  app.navigationStatus.destDist
    property string destTime:  app.navigationStatus.destTime

    Label {
        // speed
        id: speed
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.paddingMedium
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeHuge

        function update() {
            if (!py.ready) return;
            // Update speed and positioning accuracy values in user's preferred units.
            if (!gps.position.speedValid) {
                text = ""
                return;
            }

            if (app.conf.get("units") === "american") {
                text = "%1".arg(Math.round(gps.position.speed * 2.23694))
            } else if (app.conf.get("units") === "british") {
                text = "%1".arg(Math.round(gps.position.speed * 2.23694))
            } else {
                text = "%1".arg(Math.round(gps.position.speed * 3.6))
            }
        }

        Connections {
            target: gps
            onPositionChanged: speed.update()
        }

        Component.onCompleted: speed.update()
    }

    Label {
        // speed unit
        id: speedUnit
        anchors.left: speed.right
        anchors.baseline: speed.baseline
        anchors.leftMargin: Theme.paddingSmall
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeMedium

        function update() {
            if (!py.ready) return;
            if (app.conf.get("units") === "american") {
                text = app.tr("mph")
            } else if (app.conf.get("units") === "british") {
                text = app.tr("mph")
            } else {
                text = app.tr("km/h")
            }
        }

        Connections {
            target: gps
            onPositionChanged: speedUnit.update()
        }

        Component.onCompleted: speedUnit.update()
    }

    Label {
        // Time remaining to destination
        id: timeDest
        anchors.baseline: speed.baseline
        anchors.horizontalCenter: parent.horizontalCenter
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        text: block.destTime
    }

    Label {
        // Distance remaining to destination
        id: distSpace
        anchors.baseline: speed.baseline
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingMedium
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        text: block.destDist
    }

    MouseArea {
        anchors.fill: parent
        onClicked: app.showMenu();
    }
}
