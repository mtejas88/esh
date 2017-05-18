## import packages
import psycopg2
from pandas import DataFrame, concat, read_csv

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

##connect to onyx and save list of all campuses into pandas dataframe
conn = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
cur = conn.cursor()
cur.execute("""\
    	SELECT 	distinct school_nces_code, campus_id
    	FROM  public.fy2016_schools_demog_matr;""" )
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
campus_mapping = DataFrame( rows, columns=names)
cur.close()
conn.close()
print("Campus mapping pulled from database")
campus_mapping.to_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/data/interim/campus_mapping.csv')
print("File saved")
