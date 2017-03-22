import requests

cost_magnifier = 1.2

class distanceCalculator():

	def __init__(self, lat_a, lon_a, lat_b, lon_b):
		self.lat_a = lat_a
		self.lon_a = lon_a
		self.lat_b = lat_b
		self.lon_b = lon_b

	def mapboxRequest(self):
		MAPBOX_URL = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
		MAPBOX_ACCESS_TOKEN = 'pk.eyJ1IjoiZXNoLWFkbWluIiwiYSI6IkltMGhSWTgifQ.bj-sVen7BY-wC_MNwPd0uQ'
		MAPBOX_URL_PARAMS = {'access_token': MAPBOX_ACCESS_TOKEN}

		r = requests.get("{0}{1},{2};{3},{4}.json".format(	MAPBOX_URL,
															self.lon_a,
															self.lat_a,
															self.lon_b,
															self.lat_b), params = MAPBOX_URL_PARAMS)
		if r.json()['code'] == 'Ok':
		   distance = r.json()['routes'][0]['distance'] *  0.000621371
		else: #distance too close to calculate route
		   distance = 0
		return distance

class buildCostCalculator():

	def __init__(self, latitude, longitude, remotespeedmbps, assumedtypicalbuilddistancemi, latitude2, longitude2):
		self.latitude = latitude
		self.longitude = longitude
		self.remotespeedmbps = remotespeedmbps
		self.assumedtypicalbuilddistancemi = assumedtypicalbuilddistancemi
		self.latitude2 = latitude2
		self.longitude2 = longitude2

#to-do: make this class return either total cost (which it is doing now) OR nearest_central_office for IA builds
#don't know how to use r.json() in multiple functions within this class if it is created using a function
	def costquestRequest(self):
		COSTQUEST_URL = 'https://apps.costquest.com/esh/api'
		COSTQUEST_USER_ID = 'Costquest\ESHUser'
		COSTQUEST_PASS = '8kB9cQht'
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

#to-do: make class that distributes costs and incorporate into xxx_build_cost_calculator.py