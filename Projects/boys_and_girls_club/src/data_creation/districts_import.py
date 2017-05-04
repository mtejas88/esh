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
    	SELECT 	esh_id, nces_cd, district_type, include_in_universe_of_districts_all_charters, num_campuses, num_schools, exclude_from_ia_analysis, exclude_from_ia_cost_analysis, fiber_target_status, bw_target_status, current_assumed_unscalable_campuses, current_known_unscalable_campuses, fiber_metric_calc_group, 
    	case
            when exclude_from_ia_analysis = false
                then ia_bandwidth_per_student_kbps
        end as ia_bandwidth_per_student_kbps,
    	case
            when exclude_from_ia_cost_analysis = false
                then ia_bw_mbps_total
        end as ia_bw_mbps_total, 
    	case
            when exclude_from_ia_cost_analysis = false
                then ia_monthly_cost_per_mbps
        end as ia_monthly_cost_per_mbps,
    	case
            when exclude_from_ia_cost_analysis = false
                then meeting_knapsack_affordability_target
        end as meeting_knapsack_affordability_target,
        upgrade_indicator, needs_wifi
    	FROM public.fy2016_districts_deluxe_matr;""" )
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
districts = DataFrame( rows, columns=names)
cur.close()
conn.close()
print("Districts pulled from database")
districts.to_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/boys_and_girls_club/data/interim/districts.csv')
print("File saved")
