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
sys.path.insert(0, GITHUB+'/Projects_SotS_2017/connectivity/demog_breakdown')
from query import getDemogBreakdown

##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
demog = getDemogBreakdown( myConnection )
myConnection.close()
print("Demog breakdown pulled from database")

##save
demog.to_csv(GITHUB+'/Projects_SotS_2017/connectivity/demog_breakdown/data/demog.csv')
print("File saved")