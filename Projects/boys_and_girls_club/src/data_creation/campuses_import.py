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
    	SELECT 	c.*, dd.nces_cd
    	FROM public.fy2016_campus_w_fiber_nonfiber_matr c
    	LEFT JOIN public.fy2016_districts_deluxe_matr dd
    	on c.district_esh_id = dd.esh_id;""" )
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
campuses = DataFrame( rows, columns=names)
cur.close()
conn.close()
print("Campuses pulled from database")
campuses.to_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/data/interim/campuses.csv')
print("File saved")
