import math
from pandas import DataFrame, concat, read_csv
from numpy import where

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())

campuses_distances = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/campuses_distances.csv',index_col=0)
print("Campuses with distances imported")

##create parameter input if arg=1 then csv else rerun with default as csv
#calculate integer number of campuses needed and save into pandas dataframe
campus_integers = []
for i in range(0, campuses_distances.shape[0]):
	campus_integers.append({'district_num_campuses_unscalable_integer':
							math.ceil(campuses_distances['district_num_campuses_unscalable'][i])})
campus_integers = DataFrame(campus_integers)
campuses_distances = concat([campuses_distances, campus_integers], axis=1)

##sort all districts campuses by increasing distance and limit by the district_num_campuses_unscalable_integer 
    #always rank campuses with correct_nonfiber_match = 1 as 1, rank the others by distance
campuses_distances_oth = campuses_distances[campuses_distances.correct_fiber_match == 0]
campuses_distances_oth['campus_distance_rank'] = campuses_distances_oth.sort_values(['correct_nonfiber_match', 'distance'], ascending=[False, False]).groupby(['esh_id']).cumcount() + 1
unscalable_campuses = campuses_distances_oth[(campuses_distances_oth.campus_distance_rank <= campuses_distances_oth.district_num_campuses_unscalable_integer)]
unscalable_campuses = unscalable_campuses.reset_index(drop=True)

print("Campuses limited to closest unscalable")

##calculate assumed build bw needed based on campuses' number of students
unscalable_campuses['build_bandwidth'] = where(unscalable_campuses['campus_student_count']<1000, 1000, 10000)
unscalable_campuses['build_fraction_wan'] = where(unscalable_campuses['campus_distance_rank']>unscalable_campuses['district_num_campuses_unscalable'],
												1-(unscalable_campuses['campus_distance_rank']-unscalable_campuses['district_num_campuses_unscalable']),
												1)

unscalable_campuses.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/unscalable_campuses.csv')
print("File saved")
