/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2015 Osmo Salomaa
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

Text {
    anchors.left: parent.left
    anchors.leftMargin: Theme.paddingLarge
    anchors.bottomMargin: Theme.paddingLarge
    anchors.bottom: streetName.top
    width: parent.width/2
    z: 400

    color: "red"
    font.bold: true
    font.family: "sans-serif"
    font.pixelSize: Math.round(Theme.pixelRatio * 36)
    fontSizeMode: Text.Fit
    horizontalAlignment: Text.AlignLeft
    style: Text.Outline
    styleColor: "white"

    function update() {
        // Update speed and positioning accuracy values in user's preferred units.
        if (!py.ready) return;
        if (gps.speedLimit == null) {
            text = "";
            visible = false;
            return;
        }

        // speed limit in km/h
        if (app.conf.get("units") === "american") {
            text = "%1".arg(Math.round(gps.speedLimit * 0.621371))
        } else if (app.conf.get("units") === "british") {
            text = "%1".arg(Math.round(gps.speedLimit * 0.621371))
        } else {
            text = "%1".arg(gps.speedLimit)
        }

        visible = true
    }

    Connections {
        target: gps
        onPositionChanged: update()
    }

    Component.onCompleted: update()
}
