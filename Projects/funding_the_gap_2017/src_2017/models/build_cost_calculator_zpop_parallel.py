from pandas import DataFrame, concat, read_csv
from numpy import where, arange
import multiprocessing as mp

import sys, os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src')

from classes import buildCostCalculator, cost_magnifier

unscalable_campuses = read_csv('../../data/interim/unscalable_campuses.csv')
print("Unscalable campuses imported")

def processCampus(i):
	global unscalable_campuses
	print unscalable_campuses['esh_id'][i]
	sys.stdout.flush()
	outputs = buildCostCalculator(unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	return {	'campus_id': unscalable_campuses['campus_id'][i],
				'esh_id': unscalable_campuses['esh_id'][i],
				'build_cost_zpop': outputs.build_cost,
				'build_distance_zpop': outputs.distance}

inputs = range(0, unscalable_campuses.shape[0])
pool = mp.Pool(processes=4)
campus_costs_zpop = pool.map(processCampus, inputs)

print("Costs calculated Z-Pop")

campus_costs_zpop = DataFrame(campus_costs_zpop)

campus_costs_zpop.to_csv('../../data/interim/campus_costs_zpop.csv')
print("File saved")
