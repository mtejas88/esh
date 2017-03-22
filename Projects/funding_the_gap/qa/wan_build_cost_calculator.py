from pandas import DataFrame, concat, read_csv
from numpy import where, arange

from classes import buildCostCalculator, cost_magnifier

#choose one or the other for 1: rerunning 2: static
#from unscalable_campuses import unscalable_campuses
unscalable_campuses = read_csv('unscalable_campuses.csv')
print("Unscalable campuses imported")

#calculate cost for all unscalable campuses and save into pandas dataframe
campus_costs = []

for i in range(0, unscalable_campuses.shape[0]):
	cost_test = buildCostCalculator(unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i]).costquestRequest()
	campus_costs.append({'build_cost': cost_test})
	print(cost_test, file=open('./costsfile.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated")
campus_costs = DataFrame(campus_costs)
#use this code if there are timeouts
campus_costs = read_csv('costsfile.csv')
campus_costs = concat([unscalable_campuses, campus_costs], axis=1)

campus_build_costs.to_csv('campus_build_costs.csv')
print("File saved")

