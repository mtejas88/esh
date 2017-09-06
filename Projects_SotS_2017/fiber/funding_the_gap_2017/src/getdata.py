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
sys.path.insert(0, GITHUB+'/Projects_SotS_2017/fiber/funding_the_gap_2017/src')
from query import getUnscalableBreakdown

##connect to onyx and save list of all campuses into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
unscalable_breakdown = getUnscalableBreakdown( myConnection )
myConnection.close()
print("Breakdown pulled from database")

##save
unscalable_breakdown.to_csv(GITHUB+'/Projects_SotS_2017/fiber/funding_the_gap_2017/data/interim/unscalable_breakdown.csv')
print("File saved")