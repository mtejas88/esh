##imports and definitions
import psycopg2
from pandas import DataFrame, concat, read_csv, merge

import os
##from dotenv import load_dotenv, find_dotenv
##load_dotenv(find_dotenv())
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap_2017/src_2017/data_creation')
from onyx_queries import getCampuses
from classes import distanceCalculator
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src')
from credentials import MAPBOX_ACCESS_TOKEN, COSTQUEST_USER_ID, COSTQUEST_PASS

import time

##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
campuses = getCampuses( myConnection )
myConnection.close()
print("Campuses pulled from database")

##filter campuses to only those in districts that are "clean" fiber targets
campuses = campuses[(campuses.denomination == '1: Fit for FTG, Target')]
campuses = campuses.reset_index(drop=True)

##store
#campuses.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/raw/campuses.csv')

##permanent distances file
campuses_distances = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/raw/campuses_distances.csv',index_col=0, dtype={'esh_id': str, 'campus_id': str})

##determine any new campuses/districts
campuses = merge(campuses, campuses_distances[['esh_id', 'campus_id','distance']], how='left', on=['esh_id','campus_id'])

newcampuses = campuses[(campuses.distance.isnull())]
newcampuses = newcampuses.drop('distance', axis=1)
newcampuses.sample_campus_latitude=newcampuses.sample_campus_latitude.astype(float)
newcampuses.sample_campus_longitude=newcampuses.sample_campus_longitude.astype(float)

campuses = campuses[(campuses.distance.notnull())]

print("Length of new campuses is: " + str(newcampuses.shape[0]))

newcampuses = newcampuses.reset_index(drop=True)
campuses = campuses.reset_index(drop=True)

##calculate distance between all campuses and its district office and save into pandas dataframe
campus_distances = []
for i in range(newcampuses.shape[0]):
	dist_test = distanceCalculator(	newcampuses['district_latitude'][i],
									newcampuses['district_longitude'][i],
									newcampuses['sample_campus_latitude'][i],
									newcampuses['sample_campus_longitude'][i]).mapboxRequest()
	campus_distances.append({'distance': dist_test})
	time.sleep(2) # rate limit is 60 requests per minute
	if i % 50 == 0:
		print("Iteration {0} out of {1}".format(i,newcampuses.shape[0]))
	else:
		continue

print("Distances calculated")


##join distances to campuses and save
campus_distances_df = DataFrame(campus_distances)
newcampuses_distances = concat([newcampuses, campus_distances_df], axis=1)

##combine onto known distances
campuses_distances = concat([campuses, newcampuses_distances], axis=0)
campuses_distances = campuses_distances.reset_index(drop=True)

campuses_distances.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/raw/campuses_distances.csv')
campuses_distances.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campuses_distances.csv')
print("File saved")