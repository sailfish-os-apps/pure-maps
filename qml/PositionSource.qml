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
import QtPositioning 5.3

import "js/util.js" as Util

Item {
    id: gps
    
    property var direction: gps_real.direction
    property var position: gps_real.position
    property bool ready: gps_real.ready
    property var  speedLimit: undefined
    property string streetName: ""

    PositionSource {
        id: gps_real
        
        // If application is no longer active, turn positioning off immediately
        // if we already have a lock, otherwise keep trying for a couple minutes
        // and give up if we still don't gain that lock.
        active: app.running || (coordHistory.length === 0 && timePosition - timeActivate < 180000)

        property var coordHistory: []
        property var direction: undefined
        property var directionHistory: []
        property var ready: false
        property var timeActivate:  Date.now()
        property var timeDirection: Date.now()
        property var timePosition:  Date.now()

        onActiveChanged: {
            // Keep track of when positioning was (re)activated.
            if (gps_real.active) gps_real.timeActivate = Date.now();
        }

        onPositionChanged: {
            // Calculate direction as a median of individual direction values
            // calculated after significant changes in position. This should be
            // more stable than any direct value and usable with map.autoRotate.
            gps_real.ready = gps_real.position.latitudeValid &&
                gps_real.position.longitudeValid &&
                gps_real.position.coordinate.latitude &&
                gps_real.position.coordinate.longitude;
            gps_real.timePosition = Date.now();
            var threshold = gps_real.position.horizontalAccuracy || 15;
            if (threshold < 0 || threshold > 100) return;

            // Map matching
            py.call("poor.app.matcher.match", [gps_real.position.coordinate.longitude,
                                               gps_real.position.coordinate.latitude,
                                               gps_real.position.horizontalAccuracy], function(position) {
                                                   if (position == null) {
                                                       gps.position = gps_real.position;
                                                       gps.direction = gps_real.direction;
                                                       gps.streetName = "";
                                                       gps.speedLimit = undefined;
                                                   } else {
                                                       position.coordinate =
                                                           QtPositioning.coordinate(
                                                               position.latitude, position.longitude);
                                                       position.speed = position.speed || gps_real.position.speed;
                                                       position.speedValid = position.speedValid || gps_real.position.speedValid;
                                                       gps.position = position;
                                                       if (position.direction!==undefined) gps.direction = position.direction;
                                                       else gps.direction = gps_real.direction;
                                                       gps.streetName = position.street_name || "";
                                                       gps.speedLimit = position.speed_limit || undefined;
                                                   }
                                               });

            // original threshold
            if (threshold < 0 || threshold > 40) return;
            var coord = gps_real.position.coordinate;
            if (gps_real.coordHistory.length === 0)
                gps_real.coordHistory.push(QtPositioning.coordinate(
                    coord.latitude, coord.longitude));
            var coordPrev = gps_real.coordHistory[gps_real.coordHistory.length-1];
            if (coordPrev.distanceTo(coord) > threshold) {
                gps_real.coordHistory.push(QtPositioning.coordinate(
                    coord.latitude, coord.longitude));
                gps_real.coordHistory = gps_real.coordHistory.slice(-3);
                // XXX: Direction is missing from gps_real.position.
                // https://bugreports.qt.io/browse/QTBUG-36298
                var direction = coordPrev.azimuthTo(coord);
                gps_real.directionHistory.push(direction);
                gps_real.directionHistory = gps_real.directionHistory.slice(-3);
                if (gps_real.directionHistory.length >= 3) {
                    gps_real.direction = Util.median(gps_real.directionHistory);
                    gps_real.timeDirection = Date.now();
                }
            } else if (gps_real.direction && Date.now() - gps_real.timeDirection > 300000) {
                // Clear direction if we have not seen any valid updates in a while.
                gps_real.coordHistory = [];
                gps_real.direction = undefined;
                gps_real.directionHistory = [];
                py.call_sync("poor.app.matcher.clear")
                gps.direction = undefined;
                gps.streetName = "";
                gps.speedLimit = undefined;
            }
        }
    }
}


//////////////////////////////////////////////////////
//// Debug version below for usage without GPS
//////////////////////////////////////////////////////
//Item {
//    id: gps
//    property var direction: undefined
//    property var position: QtObject {
//        property var coordinate: QtPositioning.coordinate(60.16807, 24.94155)
//        property real horizontalAccuracy: 25
//        property bool horizontalAccuracyValid: true
//        property bool latitudeValid: true
//        property bool longitudeValid: true
//        property real speed: 123.0
//        property bool speedValid: true
//    }
//    property bool ready: true
//    property var  speedLimit: undefined
//    property string streetName: ""
//    Timer {
//        interval: 1000
//        repeat: true
//        running: app.running

//        // Plain static reassignment to trigger onPositionChanged.
//        // onTriggered: gps.position = gps.position;

//        // Hook position to map center point.
//        onTriggered: {
////            gps.position.coordinate = QtPositioning.coordinate(
////                map.center.latitude, map.center.longitude);
////            gps.position = gps.position;
////            gps.direction = 90;
            
//            py.call("poor.app.matcher.match", [map.center.longitude,
//                                               map.center.latitude,
//                                               gps.position.horizontalAccuracy], function(position) {
//                                                   if (position == null) {
////                                                       gps.position = gps_real.position;
////                                                       gps.direction = gps_real.direction;
//                                                       gps.streetName = "";
//                                                       gps.speedLimit = position.speed_limit || undefined;
//                                                   } else {
//                                                       position.coordinate =
//                                                           QtPositioning.coordinate(
//                                                               position.latitude, position.longitude);
//                                                       position.speed = 125;
//                                                       position.speedValid = true;
//                                                       gps.position = position;
//                                                       console.log(JSON.stringify(gps.position))
//                                                       if (position.direction!==undefined) gps.direction = position.direction;
//                                                       else gps.direction = undefined;
//                                                       gps.streetName = position.street_name || "";
//                                                       gps.speedLimit = position.speed_limit || undefined;
//                                                   }
//                                               });
//        }
//    }
//}
