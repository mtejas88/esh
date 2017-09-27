from pandas import DataFrame, concat, read_csv
from numpy import where, arange

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())

import sys
sys.path.insert(0, '/home/sat/sat_r_programs/funding_the_gap/src/features')

from classes import buildCostCalculator, cost_magnifier

unscalable_districts = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/unscalable_districts.csv',index_col=0)
print("Unscalable districts imported")

##calculate Z-PoP cost for all unscalable districts and save into pandas dataframe
district_costs = []

for i in range(0, unscalable_districts.shape[0]):
	outputs = buildCostCalculator(unscalable_districts['district_latitude'][i],
									unscalable_districts['district_longitude'][i],
									unscalable_districts['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	district_costs.append({	'esh_id': unscalable_districts['esh_id'][i],
							'district_build_cost': outputs.build_cost,
							'district_build_distance': outputs.distance})
	#print(outputs, file=open(GITHUB+'/Projects/funding_the_gap_2017/data/interim/costsfile_ia.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_districts.shape[0]))
	else:
		continue

print("Costs calculated")

## convert and save
district_costs = DataFrame(district_costs)

district_costs.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/district_costs.csv')
print("File saved")
