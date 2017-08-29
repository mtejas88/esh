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
sys.path.insert(0, GITHUB+'/Projects_SotS_2017/fiber/unscalable_match_dr')
from query import getCampusesNotMeeting

##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
summary = getCampusesNotMeeting( myConnection )
myConnection.close()
print("Campuses without fiber pulled from database")

##save
summary.to_csv(GITHUB+'/Projects_SotS_2017/fiber/unscalable_match_dr/data/summary.csv')
print("File saved")