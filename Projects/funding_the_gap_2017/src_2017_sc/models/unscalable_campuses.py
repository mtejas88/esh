import math
from pandas import DataFrame, concat, read_csv
from numpy import where

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

campuses_distances = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campuses_distances.csv',index_col=0)
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

	#always rank campuses with correct_fiber_match = 1 as 0 - will recombine later
campuses_distances_cf = campuses_distances[campuses_distances.correct_fiber_match = 1]
campuses_distances_cf['campus_distance_rank'] = 0
campuses_distances_cf = campuses_distances_cf.reset_index(drop=True)

	#always rank campuses with correct_nonfiber_match = 1 as 1
campuses_distances_cnf = campuses_distances[campuses_distances.correct_nonfiber_match = 1]
campuses_distances_cnf['campus_distance_rank'] = 1
campuses_distances_cnf = campuses_distances_cnf.reset_index(drop=True)

	#rank the others by distance
campuses_distances_oth = campuses_distances[campuses_distances.correct_fiber_match = 0 & campuses_distances.correct_nonfiber_match = 0]
campuses_distances_oth['campus_distance_rank'] = campuses_distances_oth.sort_values('distance', ascending=False).groupby(['esh_id']).cumcount() + 1
campuses_distances_oth['campus_distance_rank'] = campuses_distances_oth['campus_distance_rank'] + 1
campuses_distances_oth = campuses_distances_oth[(campuses_distances_oth.campus_distance_rank <= campuses_distances_oth.district_num_campuses_unscalable_integer)]
campuses_distances_oth = campuses_distances_oth.reset_index(drop=True)
print("Campuses limited to closest unscalable")

unscalable_campuses1 = concat([campuses_distances_cnf,campuses_distances_oth],axis=0)


##calculate assumed build bw needed based on campuses' number of students
unscalable_campuses1['build_bandwidth'] = where(unscalable_campuses1['campus_student_count']<1000, 1000, 10000)
unscalable_campuses1['build_fraction_wan'] = where((unscalable_campuses1['correct_nonfiber_match'] = 0) &
												(unscalable_campuses1['campus_distance_rank']>unscalable_campuses1['district_num_campuses_unscalable']),
												1-(unscalable_campuses1['campus_distance_rank']-unscalable_campuses1['district_num_campuses_unscalable']),
												1)
unscalable_campuses1 = unscalable_campuses1.reset_index(drop=True)

	#correct fiber campuses
campuses_distances_cf['build_bandwidth'] = where(campuses_distances_cf['campus_student_count']<1000, 1000, 10000)
campuses_distances_cf['build_fraction_wan'] = 0
campuses_distances_cf=campuses_distances_cf.reset_index(drop=True)

unscalable_campuses = concat([unscalable_campuses1,campuses_distances_cf],axis=0)

unscalable_campuses.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/unscalable_campuses.csv')
print("File saved")
