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
sys.path.insert(0, GITHUB+'/Projects_SotS_2017/fiber/state_match/histogram')
from query import getFRNswithMatch

##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
frns = getFRNswithMatch( myConnection )
myConnection.close()
print("FRNs pulled from database")

##save
frns.to_csv(GITHUB+'/Projects_SotS_2017/fiber/state_match/histogram/data/frns.csv')
print("File saved")