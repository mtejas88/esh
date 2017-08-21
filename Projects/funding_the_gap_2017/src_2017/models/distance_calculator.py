##imports and definitions
import psycopg2
from pandas import DataFrame, concat

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
HOST = os.environ.get("HOST_DENIM")
USER = os.environ.get("USER_DENIM")
PASSWORD = os.environ.get("PASSWORD_DENIM")
DB = os.environ.get("DB_DENIM")
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap_2017/src_2017/data_creation')
from onyx_queries import getCampuses
from classes import distanceCalculator
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src')
from credentials import MAPBOX_ACCESS_TOKEN, COSTQUEST_USER_ID, COSTQUEST_PASS


##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
campuses = getCampuses( myConnection )
myConnection.close()
print("Campuses pulled from database")

##filter campuses to only those in districts that are "clean" fiber targets
campuses = campuses[(campuses.denomination == '1: Fit for FTG, Target')]
campuses = campuses.reset_index(drop=True)

##calculate distance between all campuses and its district office and save into pandas dataframe
campus_distances = []
for i in range(0, campuses.shape[0]):
	dist_test = distanceCalculator(	campuses['district_latitude'][i],
									campuses['district_longitude'][i],
									campuses['sample_campus_latitude'][i],
									campuses['sample_campus_longitude'][i]).mapboxRequest()
	campus_distances.append({'distance': dist_test})
print("Distances calculated")

##join distances to campuses and save
campus_distances = DataFrame(campus_distances)
campuses_distances = concat([campuses, campus_distances], axis=1)

campuses_distances.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campuses_distances.csv')
print("File saved")