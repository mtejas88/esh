from pandas import DataFrame, concat, read_csv
from numpy import where, arange

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

import sys
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')

from classes import buildCostCalculator, cost_magnifier

unscalable_campuses = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/unscalable_campuses.csv')
print("Unscalable campuses imported")

#calculate A-Z cost for all unscalable campuses and save into pandas dataframe
campus_costs_az = []

for i in range(0, unscalable_campuses.shape[0]):
	cost_test = buildCostCalculator(unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									unscalable_campuses['distance'][i],
									unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i]).costquestRequest()
	campus_costs_az.append({	'campus_id': unscalable_campuses['campus_id'][i],
								'esh_id': unscalable_campuses['esh_id'][i],
								'build_cost_az': cost_test})
	print(cost_test, file=open('./costsfile_az.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated A-Z")

campus_costs_az = DataFrame(campus_costs_az)

campus_costs_az.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/interim/campus_costs_az.csv')
print("File saved")
