import psycopg2
from numpy import where

from onyx_credentials import hostname, username, password, database
from onyx_queries import getDistricts

#connect to onyx and save list of all districts into pandas dataframe
myConnection = psycopg2.connect( host=hostname, user=username, password=password, dbname=database )
districts = getDistricts( myConnection )
myConnection.close()
districts.to_csv('districts.csv')
print("Districts pulled from database and saved")

#only include fiber target districts without a fiber internet access connection
#to-do: why do we only use clean districts for IA builds but not WAN builds? potentially allow "No Data" to have IA build
unscalable_districts = districts[(districts.denomination == '1: Fit for FTG, Target')]
unscalable_districts = unscalable_districts[(unscalable_districts.district_exclude_from_ia_analysis == False)]
unscalable_districts = unscalable_districts[(unscalable_districts.district_hierarchy_ia_connect_category != 'Fiber')]
unscalable_districts = unscalable_districts.reset_index(drop=True)

#calculate assumed build bw needed based on district's number of students
unscalable_districts['build_bandwidth'] = where(unscalable_districts['district_num_students']<1000,
												100,
												where(	unscalable_districts['district_num_students']<10000,
														1000,
														10000))
unscalable_districts['build_fraction'] = 1
print("Districts formatted")

unscalable_districts.to_csv('unscalable_districts.csv')
print("File saved")
