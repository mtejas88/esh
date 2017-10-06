from pandas import DataFrame, read_csv
from numpy import append, column_stack

import os 
GITHUB = os.environ.get("GITHUB")

state_metrics = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/state_metrics.csv',index_col=0)
print("State metrics imported")

#create empty arrays and base arrays
value = []
methodology = []
cut = []
numbers = []
district_postal_cd = []

#loop metrics creation throughout each state
for z in range(0,len(state_metrics)):
	#add total_state_funding, total_erate_funding, total_district_funding, build_distance strings and numbers arrays
	methodology_base = ['min', 'min', 'min', 'max', 'max', 'max', 'az', 'az_pop']
	cut_base = ['overall', 'wan', 'ia', 'overall', 'wan', 'ia', 'wan', 'wan']

	for y in ['total_cost', 'total_state_funding', 'total_erate_funding', 'total_district_funding', 'build_distance']:
		for x in range(0, 8):
			value.append(y)
			district_postal_cd.append(state_metrics['district_postal_cd'][z])

		methodology = append(methodology, methodology_base)
		cut = append(cut, cut_base)

		numbers = append(numbers,
			[state_metrics['min_' + y][z],
			state_metrics['min_' + y + '_wan'][z],
			state_metrics['min_' + y + '_ia'][z],
			state_metrics['max_' + y][z],
			state_metrics['max_' + y + '_wan'][z],
			state_metrics['max_' + y + '_ia'][z],
			state_metrics[y + '_az_wan'][z],
			state_metrics[y + '_az_pop_wan'][z]])
	

	#add total_cost_per_mile, total_miles_per_build strings and numbers arrays
	methodology_base = ['min', 'max']
	cut_base = ['overall', 'overall']

	for y in ['total_cost_per_mile', 'miles_per_build', 'miles_per_build_1']:
		for x in range(0, 2):
			value.append(y)
			district_postal_cd.append(state_metrics['district_postal_cd'][z])

		methodology = append(methodology, methodology_base)
		cut = append(cut, cut_base)

		numbers = append(numbers,
			[state_metrics['min_' + y][z],
			state_metrics['max_' + y][z]])

	#advice columns
        methodology_base = ['all']
        cut_base = ['overall']

        for y in ['advice_max_cost_per_mile', 'advice_ia_builds','advice_ratio_miles_per_build','advice_skew']:
            value.append(y)
            district_postal_cd.append(state_metrics['district_postal_cd'][z])

            methodology = append(methodology, methodology_base)
            cut = append(cut, cut_base)
        numbers = append(numbers,
                                [state_metrics['advice_max_cost_per_mile'][z],
                                state_metrics['advice_ia_builds'][z],
                                state_metrics['advice_ratio_miles_per_build'][z],
                                state_metrics['advice_skew'][z]])
        
        #add builds strings and numbers arrays
	for x in range(0, 10):
		value.append('builds')
		district_postal_cd.append(state_metrics['district_postal_cd'][z])

	methodology = append(methodology, ['min', 'min', 'min','max', 'max','max','all','all', 'az', 'az_pop'])
	cut = append(cut, ['overall', 'wan', 'ia', 'overall', 'wan', 'ia','overall', 'wan','wan', 'wan'])

	numbers = append(numbers,
		[state_metrics['min_builds'][z],
		state_metrics['min_builds_wan'][z],
		state_metrics['min_builds_ia'][z],
		state_metrics['max_builds'][z],
		state_metrics['max_builds_wan'][z],
		state_metrics['max_builds_ia'][z],
		state_metrics['max_builds_1'][z],
                state_metrics['builds_wan'][z],
		state_metrics['builds_az_wan'][z],
		state_metrics['builds_az_pop_wan'][z]])

state_metrics_tableau = column_stack((district_postal_cd, methodology, value, cut, numbers))

index = [i for i in range(0, len(state_metrics_tableau))]
columns = ['district_postal_cd', 'methodology', 'value', 'cut', 'numbers']

state_metrics_tableau = DataFrame(data = state_metrics_tableau, index = index, columns = columns)

state_metrics_tableau.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/state_metrics_tableau.csv')
print("File saved")
