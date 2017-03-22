import math
from pandas import DataFrame, concat, read_csv
from numpy import where

#choose one or the other for 1: rerunning 2: static 3: new_model_v2 data
#from distance_calculator import campuses_distances
campuses_distances = read_csv('campuses_distances.csv')
#campuses_distances = read_csv('campuses_new_model_v2.csv')
print("Campuses with distances imported")

#create parameter input if arg=1 then csv else rerun with default as csv
#calculate integer number of campuses needed and save into pandas dataframe
campus_integers = []
for i in range(0, campuses_distances.shape[0]):
	campus_integers.append({'district_num_campuses_unscalable_integer':
							math.ceil(campuses_distances['district_num_campuses_unscalable'][i])})
campus_integers = DataFrame(campus_integers)
campuses_distances = concat([campuses_distances, campus_integers], axis=1)

#sort all districts campuses by increasing distance and limit by the district_num_campuses_unscalable_integer
campuses_distances['campus_distance_rank'] = campuses_distances.sort_values('distance', ascending=False).groupby(['esh_id']).cumcount() + 1
unscalable_campuses = campuses_distances[(campuses_distances.campus_distance_rank <= campuses_distances.district_num_campuses_unscalable_integer)]
unscalable_campuses = unscalable_campuses.reset_index(drop=True)
print("Campuses limited to closest unscalable")

#calculate assumed build bw needed based on campuses' number of students
unscalable_campuses['build_bandwidth'] = where(unscalable_campuses['campus_student_count']<1000, 1000, 10000)
unscalable_campuses['build_fraction'] = where(	unscalable_campuses['campus_distance_rank']>unscalable_campuses['district_num_campuses_unscalable'],
												1-(unscalable_campuses['campus_distance_rank']-unscalable_campuses['district_num_campuses_unscalable']),
												1)

unscalable_campuses.to_csv('unscalable_campuses.csv')
#unscalable_campuses.to_csv('unscalable_campuses_new_model_v2.csv')
print("File saved")
