import psycopg2
from numpy import where, logical_or, logical_and
from pandas import DataFrame, read_csv, merge, concat

import os

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap_2017/src_2017_sc/data_creation')
from onyx_queries2 import getDistricts


##connect to onyx and save list of all districts into pandas dataframe
myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
districts = getDistricts( myConnection )
myConnection.close()

districts.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/districts.csv')
print("Districts pulled from database and saved")

districts = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/districts.csv',index_col=0)
unscalable_campuses = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/unscalable_campuses.csv',index_col=0)
campus_build_costs = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campus_build_costs.csv', index_col=0)
print("Unscalable campuses imported")

unscalable_districts_with_0_wan_builds = unscalable_campuses.groupby(['esh_id']).sum()
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds[['distance']]
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds.loc[unscalable_districts_with_0_wan_builds['distance'] == 0]
unscalable_districts_with_0_wan_builds = unscalable_districts_with_0_wan_builds.reset_index()
unscalable_districts_with_0_wan_builds = DataFrame(unscalable_districts_with_0_wan_builds)

unscalable_districts_with_all_az  = campus_build_costs.groupby(['esh_id','district_num_campuses_unscalable_integer']).sum()
##move the index to a column so we can use the values
unscalable_districts_with_all_az['district_num_campuses_unscalable_integer_col']=unscalable_districts_with_all_az.index.get_level_values('district_num_campuses_unscalable_integer')
unscalable_districts_with_all_az.sort_index(inplace=True)
##filter for districts where every build (lowest cost) is AZ
unscalable_districts_with_all_az = unscalable_districts_with_all_az[unscalable_districts_with_all_az['az_min'] == unscalable_districts_with_all_az['district_num_campuses_unscalable_integer_col']]
unscalable_districts_with_all_az = unscalable_districts_with_all_az[['az_min']]
unscalable_districts_with_all_az = unscalable_districts_with_all_az.reset_index()
unscalable_districts_with_all_az = DataFrame(unscalable_districts_with_all_az)

#filter for Targets with hierarchy_ia_connect_category != Fiber for all
unscalable_districts = districts[(districts.denomination == '1: Fit for FTG, Target')]
unscalable_districts = unscalable_districts[(unscalable_districts.district_hierarchy_ia_connect_category != 'Fiber')]

##combine with the AZ districts
unscalable_districtsAZ = unscalable_districts.merge(unscalable_districts_with_all_az, left_on='esh_id', right_on='esh_id', how='left')
unscalable_districtsAZ = unscalable_districtsAZ[(unscalable_districtsAZ.az_min >= 1)]
unscalable_districtsAZ = unscalable_districtsAZ.reset_index()
unscalable_districtsAZ.drop(['index', 'district_num_campuses_unscalable_integer','az_min'], axis=1, inplace=True)

##apply old logic
unscalable_districts0 = unscalable_districts.merge(unscalable_districts_with_0_wan_builds, left_on='esh_id', right_on='esh_id', how='left')
unscalable_districts0 = unscalable_districts0[logical_or(unscalable_districts0.district_num_campuses_unscalable == 0,
                                                logical_and(unscalable_districts0.district_num_campuses_unscalable > 0, unscalable_districts0.distance == 0))]
unscalable_districts0 = unscalable_districts0.reset_index()
unscalable_districts0.drop(['index', 'distance'], axis=1, inplace=True)

##combine (if necessary)
unscalable_districts = concat([unscalable_districtsAZ,unscalable_districts0], axis=0)
unscalable_districts = unscalable_districts.reset_index(drop=True)

unscalable_districts.drop_duplicates(inplace=True)
unscalable_districts = unscalable_districts.reset_index(drop=True)

##calculate assumed build bw needed based on district's number of students
unscalable_districts['build_bandwidth'] = where(unscalable_districts['district_num_students']<1000,
												100,
												where(	unscalable_districts['district_num_students']<10000,
														1000,
														10000))
unscalable_districts['build_fraction_ia'] = 1
print("Districts formatted")

unscalable_districts.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/unscalable_districts.csv')
print("File saved")
