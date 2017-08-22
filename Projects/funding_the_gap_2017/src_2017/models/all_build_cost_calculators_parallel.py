from pandas import DataFrame, concat, read_csv
from dotenv import load_dotenv, find_dotenv
import multiprocessing as mp
import sys, os

load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")
sys.path.insert(0, GITHUB+'/Projects/funding_the_gap/src/features')

# Set this to the number of parallel threads you want to run
NUMPROCS = 8

from classes import buildCostCalculator, cost_magnifier

unscalable_campuses = read_csv('../../data/interim/unscalable_campuses.csv')
print("Unscalable campuses imported")

def calculateAPop(i):
	global unscalable_campuses
	outputs = buildCostCalculator(	unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	return {	'campus_id': unscalable_campuses['campus_id'][i],
				'esh_id': unscalable_campuses['esh_id'][i],
				'build_cost_apop': outputs.build_cost,
				'build_distance_apop': outputs.distance})

def calculateZPop(i):
	global unscalable_campuses
	outputs = buildCostCalculator(	unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	return {	'campus_id': unscalable_campuses['campus_id'][i],
				'esh_id': unscalable_campuses['esh_id'][i],
				'build_cost_zpop': outputs.build_cost,
				'build_distance_zpop': outputs.distance}

def calculateAZ(i):
	global unscalable_campuses
	outputs = buildCostCalculator(	unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									unscalable_campuses['distance'][i],
									unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i]).costquestRequest()
	return {	'campus_id': unscalable_campuses['campus_id'][i],
				'esh_id': unscalable_campuses['esh_id'][i],
				'build_cost_az': cost_test}

def calculateIA(i):
	unscalable_districts = read_csv('../../data/interim/unscalable_districts.csv')
	print("Unscalable districts imported")
	outputs = buildCostCalculator(	unscalable_districts['district_latitude'][i],
									unscalable_districts['district_longitude'][i],
									unscalable_districts['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	return {	'esh_id': unscalable_districts['esh_id'][i],
				'district_build_cost': outputs.build_cost,
				'district_build_distance': outputs.distance})


inputs = range(0, unscalable_campuses.shape[0])

pool = mp.Pool(processes = NUMPROCS)

# A-PoP
print("Calculating A-PoP")
campus_costs_apop = pool.map(calculateAPop, inputs)
print("Costs calculated A-Pop")
campus_costs_apop = DataFrame(campus_costs_apop)
campus_costs_apop.to_csv('../../data/interim/campus_costs_apop.csv')
print("File saved")

# Z-PoP
print("Calculating Z-Pop")
campus_costs_zpop = pool.map(calculateZPop, inputs)
print("Costs calculated Z-Pop")
campus_costs_zpop = DataFrame(campus_costs_zpop)
campus_costs_zpop.to_csv('../../data/interim/campus_costs_zpop.csv')
print("File saved")

# A-Z
print("Calculating A-Z")
campus_costs_az = pool.map(calculateAZ, inputs)
print("Costs calculated A-Z")
campus_costs_az = DataFrame(campus_costs_az)
campus_costs_az.to_csv('../../data/interim/campus_costs_az.csv')
print("File saved")

# Districts Z-PoP
print("Calculating Districts Z-PoP")
district_costs = pool.map(calculateIA, inputs)
print("Costs calculated Districts Z-PoP")
district_costs = DataFrame(district_costs)
district_costs.to_csv('../../data/interim/district_costs.csv')
print("File saved")
