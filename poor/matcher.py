# -*- coding: utf-8 -*-

# Copyright (C) 2018 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""Map matching."""

import json
import math
import poor
import urllib.parse

__all__ = ("Matcher",)


class Matcher:

    """Map matching."""

    distance_skip_matching = 2.0
    distance_remeber = 10.0

    def __init__(self):
        self.positions = []
        self.last_position = None
        self.last_result = None

    def match(self, lon, lat, accuracy):
        n = { "lat": lat, "lon": lon }
        if len(self.positions) > 3:
            del self.positions[0]

        if len(self.positions) < 1:
            self.positions.append(n)
            return None

        if self.last_position is not None and poor.util.calculate_distance(lon, lat,
                                                                           self.last_position["lon"],
                                                                           self.last_position["lat"]) < self.distance_skip_matching:
            return self.last_result
        
        p = self.positions[-1]
        d = poor.util.calculate_distance(lon, lat, p["lon"], p["lat"])
        if d > 10 and d > accuracy*2:
            self.positions.append(n)
            pos = self.positions
        else:
            pos = []
            pos.extend(self.positions)
            pos.append(n)

        task = dict(shape = pos,
                    costing = "auto",
                    gps_accuracy = accuracy,
                    shape_match = "map_snap")

        result = poor.http.get_json(
            'http://localhost:8553/v2/trace_attributes?json=' +
            urllib.parse.quote(json.dumps(task)))

        mpoints = result.get("matched_points", [])
        if len(mpoints) == len(pos) and mpoints[-1].get('type', '') != 'unmatched':
            p = mpoints[-1]
            e = result['edges'][p['edge_index']]
            ed = p['distance_along_edge']
            a0, a1 = math.radians(e['begin_heading']), math.radians(e['end_heading'])
            d0_x, d0_y = math.cos(a0), math.sin(a0)
            d1_x, d1_y = math.cos(a1), math.sin(a1)
            direction = math.degrees(math.atan2(d0_y*(1-ed)+d1_y*ed, d0_x*(1-ed)+d1_x*ed))
            sn = e.get('names', None)
            if sn is not None: street_name = '; '.join(sn)
            else: street_name = None
            r = {
                'latitude': p['lat'], 'longitude': p['lon'],
                'horizontalAccuracy': accuracy,
                'horizontalAccuracyValid': True,
                'latitudeValid': True,
                'longitudeValid': True,
                'direction': direction,
                'street_name': street_name,
                'speed_limit': e.get('speed_limit', None),
                'surface':  e.get('surface', None),
            }

            self.last_position = n
            self.last_result = r
            return r

        return None

    def clear(self):
        self.positions = []
