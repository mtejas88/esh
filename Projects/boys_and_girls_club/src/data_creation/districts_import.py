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
    	SELECT 	esh_id, nces_cd, district_type, include_in_universe_of_districts_all_charters, num_campuses, num_schools, exclude_from_ia_analysis, exclude_from_ia_cost_analysis, fiber_target_status, bw_target_status, current_assumed_unscalable_campuses, current_known_unscalable_campuses, fiber_metric_calc_group, ia_bandwidth_per_student_kbps, meeting_knapsack_affordability_target
    	FROM public.fy2016_districts_deluxe_matr;""" )
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
districts = DataFrame( rows, columns=names)
cur.close()
conn.close()
print("Districts pulled from database")
districts.to_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/data/interim/districts.csv')
print("File saved")
