from pandas import DataFrame, concat, read_csv
from numpy import where, arange

import sys
sys.path.insert(0, '../features')

from classes import buildCostCalculator, cost_magnifier

unscalable_campuses = read_csv('../../data/interim/unscalable_campuses.csv')
print("Unscalable campuses imported")

#calculate A-PoP cost for all unscalable campuses and save into pandas dataframe
campus_costs_apop = []

for i in range(0, unscalable_campuses.shape[0]):
	outputs = buildCostCalculator(unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	campus_costs_apop.append({	'campus_id': unscalable_campuses['campus_id'][i],
								'esh_id': unscalable_campuses['esh_id'][i],
								'build_cost_apop': outputs.build_cost,
								'build_distance_apop': outputs.distance})
	print(outputs, file=open('./costsfile_apop.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated A-Pop")

campus_costs_apop = DataFrame(campus_costs_apop)

campus_costs_apop.to_csv('../../data/interim/campus_costs_apop.csv')
print("File saved")
