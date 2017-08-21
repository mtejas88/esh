import requests
from collections import namedtuple

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src')
from credentials import MAPBOX_ACCESS_TOKEN, COSTQUEST_USER_ID, COSTQUEST_PASS

cost_magnifier = 1.2

class distanceCalculator():

	def __init__(self, lat_a, lon_a, lat_b, lon_b):
		self.lat_a = lat_a
		self.lon_a = lon_a
		self.lat_b = lat_b
		self.lon_b = lon_b

	def mapboxRequest(self):
		MAPBOX_URL = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
		MAPBOX_URL_PARAMS = {'access_token': MAPBOX_ACCESS_TOKEN}

		r = requests.get("{0}{1},{2};{3},{4}.json".format(	MAPBOX_URL,
															self.lon_a,
															self.lat_a,
															self.lon_b,
															self.lat_b), params = MAPBOX_URL_PARAMS)
		if r.json()['code'] == 'Ok':
		   distance = r.json()['routes'][0]['distance'] *  0.000621371
		else: #distance too close to calculate route
		   distance = -1
		return distance

class buildCostCalculator():

	def __init__(self, latitude, longitude, remotespeedmbps, assumedtypicalbuilddistancemi, latitude2, longitude2):
		self.latitude = latitude
		self.longitude = longitude
		self.remotespeedmbps = remotespeedmbps
		self.assumedtypicalbuilddistancemi = assumedtypicalbuilddistancemi
		self.latitude2 = latitude2
		self.longitude2 = longitude2

	def costquestRequest(self):
		COSTQUEST_URL = 'https://apps.costquest.com/esh/api'
		MAPBOX_URL_PARAMS = {	'latitude': self.latitude,
								'longitude': self.longitude,
								'remotespeedmbps': self.remotespeedmbps,
								'assumedtypicalbuilddistancemi': self.assumedtypicalbuilddistancemi,
								'latitude2': self.latitude2,
								'longitude2': self.longitude2}

		r = requests.get("{0}".format(COSTQUEST_URL), params = MAPBOX_URL_PARAMS, auth=(COSTQUEST_USER_ID, COSTQUEST_PASS))
		if r.json()['Message'] == 'Success':
			school_node = r.json()['ModelData']['EstimatedElectronicsSchoolNode']
			high_outside_plant_cost = r.json()['ModelData']['EstimatedOSPHigh']
			high_yearly_maintenance = r.json()['ModelData']['EstimatedYearlyMaintenanceHigh']
			high_replacement_cost = r.json()['ModelData']['EstimatedReplacementCapitalHigh']
			build_cost = school_node + high_outside_plant_cost + high_yearly_maintenance + high_replacement_cost
		else: build_cost = -1
		return build_cost

	def costquestRequestWithDistance(self):
		COSTQUEST_URL = 'https://apps.costquest.com/esh/api'
		MAPBOX_URL_PARAMS = {	'latitude': self.latitude,
								'longitude': self.longitude,
								'remotespeedmbps': self.remotespeedmbps,
								'assumedtypicalbuilddistancemi': self.assumedtypicalbuilddistancemi,
								'latitude2': self.latitude2,
								'longitude2': self.longitude2}

		r = requests.get("{0}".format(COSTQUEST_URL), params = MAPBOX_URL_PARAMS, auth=(COSTQUEST_USER_ID, COSTQUEST_PASS))
		if r.json()['Message'] == 'Success':
			school_node = r.json()['ModelData']['EstimatedElectronicsSchoolNode']
			high_outside_plant_cost = r.json()['ModelData']['EstimatedOSPHigh']
			high_yearly_maintenance = r.json()['ModelData']['EstimatedYearlyMaintenanceHigh']
			high_replacement_cost = r.json()['ModelData']['EstimatedReplacementCapitalHigh']
			build_cost = school_node + high_outside_plant_cost + high_yearly_maintenance + high_replacement_cost
			distance = r.json()['ServiceAreaData']['DistanceToCentralOfficeMi']
		else:
			build_cost = -1
			distance = -1
		return namedtuple('point','build_cost,distance')(build_cost,distance)

#to-do: make class that distributes costs and incorporate into xxx_build_cost_calculator.py