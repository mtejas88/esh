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

unscalable_districts = read_csv('../../data/interim/unscalable_districts.csv')
print("Unscalable districts imported")

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
				'build_distance_apop': outputs.distance}

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
				'build_cost_az': outputs}

def calculateIA(i):
	global unscalable_districts
	outputs = buildCostCalculator(	unscalable_districts['district_latitude'][i],
									unscalable_districts['district_longitude'][i],
									unscalable_districts['build_bandwidth'][i],
									0,
									0,
									0).costquestRequestWithDistance()
	return {	'esh_id': unscalable_districts['esh_id'][i],
				'district_build_cost': outputs.build_cost,
				'district_build_distance': outputs.distance}


def calculateBuildCosts(func, inputs, outputFile):
	costs = DataFrame(pool.map(func, inputs))
	costs.to_csv('../../data/interim/' + outputFile)
	print("File saved")
	sys.stdout.flush()

campuses_range = range(0, unscalable_campuses.shape[0])
districts_range = range(0, unscalable_districts.shape[0])

pool = mp.Pool(processes = NUMPROCS)

print("Calculating A-PoP")
sys.stdout.flush()
calculateBuildCosts(calculateAPop, campuses_range, 'campus_costs_apop.csv')

print("Calculating Z-Pop")
sys.stdout.flush()
calculateBuildCosts(calculateZPop, campuses_range, 'campus_costs_zpop.csv')

print("Calculating A-Z")
sys.stdout.flush()
calculateBuildCosts(calculateAZ, campuses_range, 'campus_costs_az.csv')

print("Calculating Districts Z-PoP")
sys.stdout.flush()
calculateBuildCosts(calculateIA, districts_range, 'district_costs.csv')