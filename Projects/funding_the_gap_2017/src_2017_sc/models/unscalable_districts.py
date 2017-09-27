import psycopg2
from numpy import where, logical_or, logical_and
from pandas import DataFrame, read_csv, merge

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

import sys
sys.path.insert(0, '/home/sat/sat_r_programs/funding_the_gap/src/features')
sys.path.insert(0, '/home/sat/sat_r_programs/funding_the_gap_2017/src_2017_sc/data_creation')
from onyx_queries2 import getDistricts


##connect to onyx and save list of all districts into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
districts = getDistricts( myConnection )
myConnection.close()

districts.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/districts.csv')
print("Districts pulled from database and saved")

districts = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/districts.csv',index_col=0)
unscalable_campuses = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/unscalable_campuses.csv',index_col=0)
print("Unscalable campuses imported")

unscalable_districts_with_0_wan_builds = unscalable_campuses.groupby(['esh_id']).sum()
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds[['distance']]
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds.loc[unscalable_districts_with_0_wan_builds['distance'] == 0]
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds.reset_index()
unscalable_districts_with_0_wan_builds = DataFrame(unscalable_districts_with_0_wan_builds)

districts = districts.merge(unscalable_districts_with_0_wan_builds, left_on='esh_id', right_on='esh_id', how='outer')

unscalable_districts = districts[(districts.denomination == '1: Fit for FTG, Target')]
unscalable_districts = unscalable_districts[(unscalable_districts.district_hierarchy_ia_connect_category != 'Fiber')]
unscalable_districts = unscalable_districts[logical_or(unscalable_districts.district_num_campuses_unscalable == 0,
											logical_and(unscalable_districts.district_num_campuses_unscalable > 0, unscalable_districts.distance == 0))]
unscalable_districts = unscalable_districts.reset_index(drop=True)

##calculate assumed build bw needed based on district's number of students
unscalable_districts['build_bandwidth'] = where(unscalable_districts['district_num_students']<1000,
												100,
												where(	unscalable_districts['district_num_students']<10000,
														1000,
														10000))
unscalable_districts['build_fraction_ia'] = 1
print("Districts formatted")

unscalable_districts.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/unscalable_districts.csv')
print("File saved")
