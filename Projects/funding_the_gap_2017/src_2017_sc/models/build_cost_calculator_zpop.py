from pandas import DataFrame, concat, read_csv
from numpy import where, arange

import os
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')

from classes import buildCostCalculator, cost_magnifier

unscalable_campuses = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/unscalable_campuses.csv',index_col=0)
print("Unscalable campuses imported")

##calculate Z-PoP cost for all unscalable campuses and save into pandas dataframe
campus_costs_zpop = []

for i in range(0, unscalable_campuses.shape[0]):
	outputs = buildCostCalculator(unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	campus_costs_zpop.append({	'campus_id': unscalable_campuses['campus_id'][i],
								'esh_id': unscalable_campuses['esh_id'][i],
								'build_cost_zpop': outputs.build_cost,
								'build_distance_zpop': outputs.distance})
	#print(outputs, file=open(GITHUB+'/Projects/funding_the_gap_2017/data/interim/costsfile_zpop.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated Z-Pop")

## convert and save
campus_costs_zpop = DataFrame(campus_costs_zpop)

campus_costs_zpop.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campus_costs_zpop.csv')
print("File saved")
