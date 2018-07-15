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
    anchors.left: app.menuButton.right
    anchors.right: parent.right
    anchors.rightMargin: Theme.paddingSmall
    anchors.verticalCenter: app.northArrow.verticalCenter
    z: 400

    color: "black"
    font.bold: true
    font.family: "sans-serif"
    font.pixelSize: Math.round(Theme.pixelRatio * 36)
    fontSizeMode: Text.Fit
    horizontalAlignment: Text.AlignRight
    style: Text.Outline
    styleColor: "white"

    function update() {
        // Update speed and positioning accuracy values in user's preferred units.
        if (!gps.position.speedValid) {
            text = ""
            return;
        }

        if (app.conf.get("units") === "american") {
            text = "%1 %2".arg(Math.round(gps.position.speed * 2.23694)).arg(app.tr("mph"))
        } else if (app.conf.get("units") === "british") {
            text = "%1 %2".arg(Math.round(gps.position.speed * 2.23694)).arg(app.tr("mph"))
        } else {
            text = "%1 %2".arg(Math.round(gps.position.speed * 3.6)).arg(app.tr("km/h"))
        }
    }

    Connections {
        target: gps
        onPositionChanged: update()
    }

    Component.onCompleted: update()
}
