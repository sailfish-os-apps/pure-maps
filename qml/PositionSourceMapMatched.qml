import QtQuick 2.0
import QtPositioning 5.2
import Nemo.DBus 2.0

Item {
    id: master

    // Properties
    property alias active: gps.active
    property real  direction: 0
    property bool  directionValid: false
    property alias mapMatchingAvailable: scoutbus.available
    property alias mapMatchingMode: scoutbus.mode
    property alias name: gps.name
    property var   position: gps.position
    property alias preferredPositioningMethods: gps.preferredPositioningMethods
    property alias sourceError: gps.sourceError
    property string streetName: ""
    property real  streetSpeedAssumed: -1  // in m/s
    property real  streetSpeedLimit: -1    // in m/s
    property alias supportedPositioningMethods: gps.supportedPositioningMethods
    property alias updateInterval: gps.updateInterval
    property alias valid: gps.valid

    // Signals
    signal updateTimeout()

    // Methods
    function start() {
        gps.start()
    }

    function stop() {
        gps.stop()
    }

    function update() {
        gps.update()
    }

    //////////////////////////////////////////////////////////////
    /// Implementation
    //////////////////////////////////////////////////////////////

    PositionSource {
        id: gps
        active: true
        onPositionChanged: {
            if (scoutbus.available &&
                    scoutbus.mode &&
                    position.latitudeValid && position.longitudeValid &&
                    position.horizontalAccuracyValid) {
                scoutbus.mapMatch(position);
            } else {
                master.position = position;
                if (scoutbus.mode && scoutbus.running)
                    scoutbus.stop();
            }
        }

        //onUpdateTimeout: master.updateTimeout()
    }

    DBusInterface {
        id: scoutbus
        service: "org.osm.scout.server1"
        path: "/org/osm/scout/server1/mapmatching1"
        iface: "org.osm.scout.server1.mapmatching1"

        property bool available: false
        property int  mode: 0
        property bool running: false;

        Component.onCompleted: {
            checkAvailable();
        }

        function checkAvailable() {
            if (getProperty("Active")) {
                if (!available) {
                    available = true;
                    if (mode) call('Reset', mode);
                }
            } else {
                available = false
                if (mode) resetValues();
            }
            console.log("Available: " + available)
        }

        function mapMatch(position) {
            if (!mode || !available) return;

            typedCall("Update",
                      [ {'type': 'i', 'value': mode},
                        {'type': 'd', 'value': position.coordinate.latitude},
                        {'type': 'd', 'value': position.coordinate.longitude},
                        {'type': 'd', 'value': position.horizontalAccuracy} ],
                      function(result) {
                          // successful call
                          var r = JSON.parse(result);
                          var position = JSON.parse(JSON.stringify(gps.position))

                          if (r.latitude !== undefined && r.longitude !== undefined) {
                              position.coordinate = QtPositioning.coordinate(r.latitude, r.longitude);
                          } else {
                              position.coordinate = master.position.coordinate;
                          }

                          if (r.direction) master.direction = r.direction;
                          if (r.direction_valid) master.directionValid = r.direction_valid;
                          if (r.street_name!==undefined) master.streetName = r.street_name;
                          if (r.street_speed_assumed!==undefined) master.streetSpeedAssumed = r.street_speed_assumed;
                          if (r.street_speed_limit!==undefined) master.streetSpeedLimit = r.street_speed_limit;

                          // always update position
                          master.position = position;
                      },
                      function(result) {
                          // error
                          scoutbus.resetValues();
                          master.position = gps.position;
                      }
                      );

            running = true;
        }

        function resetValues() {
            master.directionValid = false;
            master.streetName = ""
            master.streetSpeedAssumed = -1;
            master.streetSpeedLimit = -1;
        }

        function stop() {
            if (mode) {
                call('Stop', mode);
                if (gps.active) resetValues();
            }
            running = false;
        }

        onModeChanged: {
            if (!available) return;
            if (mode) call('Reset', mode);
        }
    }

    DBusInterface {
        // monitors availibility of the dbus service
        service: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        iface: "org.freedesktop.DBus"
        signalsEnabled: true

        function nameOwnerChanged(name, old_owner, new_owner) {
            if (name === scoutbus.service)
                scoutbus.checkAvailable()
        }
    }

//    // debug
//    Timer {
//        interval: 1000
//        running: true
//        repeat: true
//        property real lat: 59.4370
//        property real lon: 24.7536
//        onTriggered: {
//            lat = lat - 0.0001;
//            lon = lon - 0.0001;
//            var position = {}; // = gps.position;
//            position.coordinate = QtPositioning.coordinate(lat, lon);
//            position.horizontalAccuracy = 15.0;
//            scoutbus.mapMatch(position);
//        }
//    }
}
