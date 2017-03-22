from pandas import DataFrame, concat, read_csv
from numpy import where

from classes import buildCostCalculator, cost_magnifier

#choose one or the other for 1: rerunning 2: static
#from unscalable_districts import unscalable_districts
unscalable_districts = read_csv('unscalable_districts.csv')
print("Unscalable districts imported")

#calculate cost for unscalable districts and save into pandas dataframe
district_costs = []
for i in range(0, unscalable_districts.shape[0]):
	district_costs.append({	'build_cost':
							buildCostCalculator(unscalable_districts['district_latitude'][i],
												unscalable_districts['district_longitude'][i],
												unscalable_districts['build_bandwidth'][i],
												0,
												0,
												0).costquestRequest()})
print("Costs calculated")
district_costs = DataFrame(district_costs)
district_costs = concat([unscalable_districts, district_costs], axis=1)

#finalize costs to-do OUT OF DATE, see WAN
district_costs['total_cost'] = district_costs['build_fraction']*district_costs['build_cost']*cost_magnifier
#campus_costs['cost_per_mile'] = campus_costs['total_cost']/campus_costs['distance'] ##need to import distance from costquest
district_costs['discount_erate_funding'] = district_costs['total_cost']*district_costs['c1_discount_rate_or_state_avg']
district_costs['state_match_rate'] = where(district_costs['c1_discount_rate_or_state_avg']<.9,.1,.05)
district_costs['total_state_funding'] = district_costs['total_cost']*district_costs['state_match_rate']
district_costs['total_erate_funding'] = district_costs['total_state_funding']+district_costs['discount_erate_funding']
district_costs['total_district_funding'] = district_costs['total_cost']-district_costs['total_erate_funding']-district_costs['total_state_funding']
print("Costs finalized")

district_costs.to_csv('district_costs.csv')
print("File saved")