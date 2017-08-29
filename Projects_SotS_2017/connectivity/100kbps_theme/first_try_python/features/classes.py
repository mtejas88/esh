import requests
import time
from collections import namedtuple
from ratelimit import rate_limited
import sys
sys.path.insert(0, '../')
from credentials import MAPBOX_ACCESS_TOKEN

class distanceCalculator():

    def __init__(self, lat_a, lon_a, lat_b, lon_b):
        self.lat_a = lat_a
        self.lon_a = lon_a
        self.lat_b = lat_b
        self.lon_b = lon_b
    #@rate_limited(2)
    def mapboxRequest(self):
        MAPBOX_URL = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
        MAPBOX_URL_PARAMS = {'access_token': MAPBOX_ACCESS_TOKEN}
        r = requests.get("{0}{1},{2};{3},{4}.json".format(MAPBOX_URL,
                                                            self.lon_a,
                                                            self.lat_a,
                                                            self.lon_b,
                                                            self.lat_b), params = MAPBOX_URL_PARAMS)
     
        if r.json()['code'] == 'Ok':
            distance = r.json()['routes'][0]['distance'] *  0.000621371
        else: #distance too close to calculate route
            distance = -1
        return distance

