import psycopg2
from pandas import DataFrame, concat

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

#sys.path.insert(0, '../')
#from credentials import HOST, USER, PASSWORD, DB

import sys
sys.path.insert(0, '../features')
sys.path.insert(0, '../data_creation')
from onyx_queries import getCampuses
from classes import distanceCalculator

#connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
campuses = getCampuses( myConnection )
myConnection.close()
print("Campuses pulled from database")

#filter campuses to only those in districts that are "clean" fiber targets
campuses = campuses[(campuses.denomination == '1: Fit for FTG, Target')]
campuses = campuses.reset_index(drop=True)

#calculate distance between all campuses and its district office and save into pandas dataframe
campus_distances = []
for i in range(0, campuses.shape[0]):
	dist_test = distanceCalculator(	campuses['district_latitude'][i],
									campuses['district_longitude'][i],
									campuses['sample_campus_latitude'][i],
									campuses['sample_campus_longitude'][i]).mapboxRequest()
	campus_distances.append({'distance': dist_test})

print("Distances calculated")

campus_distances = DataFrame(campus_distances)
campuses_distances = concat([campuses, campus_distances], axis=1)

campuses_distances.to_csv('../../data/interim/campuses_distances.csv')
print("File saved")