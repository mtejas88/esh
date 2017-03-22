from pandas import DataFrame, concat, read_csv
from numpy import where, arange

from classes import buildCostCalculator, cost_magnifier

#choose one or the other for 1: rerunning 2: static 3: FTG
#from unscalable_campuses import unscalable_campuses
#unscalable_campuses = read_csv('unscalable_campuses.csv')
unscalable_campuses = read_csv('unscalable_campuses_new_model_2_10.csv')
print("Unscalable campuses imported")

#calculate cost for all unscalable campuses and save into pandas dataframe
campus_costs_a_z = []

for i in range(0, unscalable_campuses.shape[0]):
	cost_test = buildCostCalculator(unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									unscalable_campuses['distance'][i],
									unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i]).costquestRequest()
	campus_costs_a_z.append({'build_cost_a_z': cost_test})
	print(cost_test, file=open('./costsfile_a_z.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated A-Z")
campus_costs_a_z = DataFrame(campus_costs_a_z)
#use this code if there are timeouts
#campus_costs_a_z = read_csv('costsfile_a_z.csv')
campus_build_costs_pop = concat([unscalable_campuses, campus_costs_a_z], axis=1)



campus_costs_a_pop = []

for i in range(0, unscalable_campuses.shape[0]):
	cost_test = buildCostCalculator(unscalable_campuses['sample_campus_latitude'][i],
									unscalable_campuses['sample_campus_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequest()
	campus_costs_a_pop.append({'build_cost_a_pop': cost_test})
	print(cost_test, file=open('./costsfile_a_pop.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated A-Pop")
campus_costs_a_pop = DataFrame(campus_costs_a_pop)
#use this code if there are timeouts
#campus_costs_a_pop = read_csv('costsfile_a_pop.csv')
campus_build_costs_pop = concat([campus_build_costs_pop, campus_costs_a_pop], axis=1)



campus_costs_z_pop = []

for i in range(0, unscalable_campuses.shape[0]):
	cost_test = buildCostCalculator(unscalable_campuses['district_latitude'][i],
									unscalable_campuses['district_longitude'][i],
									unscalable_campuses['build_bandwidth'][i],
									0,
									0,
									0).costquestRequest()
	campus_costs_z_pop.append({'build_cost_z_pop': cost_test})
	print(cost_test, file=open('./costsfile_z_pop.csv', 'a'))
	if i % 250 == 0:
		print("Iteration {0} out of {1}".format(i,unscalable_campuses.shape[0]))
	else:
		continue

print("Costs calculated Z-Pop")
campus_costs_z_pop = DataFrame(campus_costs_z_pop)
#use this code if there are timeouts
#campus_costs_a_pop = read_csv('costsfile_a_pop.csv')
campus_build_costs_pop = concat([campus_build_costs_pop, campus_costs_z_pop], axis=1)

campus_build_costs_pop.to_csv('campus_build_costs_pop.csv')
print("File saved")