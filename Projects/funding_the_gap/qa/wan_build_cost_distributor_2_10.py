from pandas import read_csv
from numpy import where

from classes import cost_magnifier


#choose one or the other for 1: rerunning 2: static 3:FTG
#from wan_build_cost_calculator_2_10 import campus_build_costs_pop
#campus_build_costs_pop = read_csv('campus_build_costs_pop.csv')
campus_build_costs_pop = read_csv('campus_build_costs_pop_new_model_2_10.csv')
print("Campuses costs imported")


campus_build_costs_pop['build_cost_az_pop'] = campus_build_costs_pop['build_cost_a_pop']+campus_build_costs_pop['build_cost_z_pop']
campus_build_costs_pop['min_build_cost'] = campus_build_costs_pop[['build_cost_az_pop', 'build_cost_a_z']].min(axis=1)
campus_build_costs_pop['max_build_cost'] = campus_build_costs_pop[['build_cost_az_pop', 'build_cost_a_z']].max(axis=1)


campus_build_costs_pop['state_match_rate'] = where(	campus_build_costs_pop['c1_discount_rate_or_state_avg']>.8,
													(1-campus_build_costs_pop['c1_discount_rate_or_state_avg'])/2,
													.1)

#to-do: confirm that campuses with 0 distance should have 0 build cost.
# ~300 districts that are in your model with ~1 unscalable campus but the only campuses in that district returned 0 distance.
# however, when you submit them to costquest, they return a build cost. i don't think we always want to assume the build cost is 0 because the distance is 0;
#in some instances, the distance along a road just isnt able to be calculated.
campus_build_costs_pop['min_total_cost'] = where(	campus_build_costs_pop['distance']==0,
													0,
													campus_build_costs_pop['min_build_cost']*campus_build_costs_pop['build_fraction']*cost_magnifier)
campus_build_costs_pop.min_total_cost = campus_build_costs_pop.min_total_cost.round(decimals = 2)
campus_build_costs_pop['min_discount_erate_funding'] = campus_build_costs_pop['min_total_cost']*campus_build_costs_pop['c1_discount_rate_or_state_avg']
campus_build_costs_pop.min_discount_erate_funding = campus_build_costs_pop.min_discount_erate_funding.round(decimals = 2)
campus_build_costs_pop['min_total_state_funding'] = campus_build_costs_pop['min_total_cost']*campus_build_costs_pop['state_match_rate']
campus_build_costs_pop.min_total_state_funding = campus_build_costs_pop.min_total_state_funding.round(decimals = 2)
campus_build_costs_pop['min_total_erate_funding'] = campus_build_costs_pop['min_total_state_funding']+campus_build_costs_pop['min_discount_erate_funding']
campus_build_costs_pop['min_total_district_funding'] = campus_build_costs_pop['min_total_cost']-campus_build_costs_pop['min_total_erate_funding']-campus_build_costs_pop['min_total_state_funding']
campus_build_costs_pop['min_total_district_funding'] = where(	(campus_build_costs_pop.min_total_district_funding.round(decimals=2)>=-.01) & (campus_build_costs_pop.min_total_district_funding.round(decimals=2)<=.01),
																0,
																campus_build_costs_pop['min_total_district_funding'])

#to-do: confirm that campuses with 0 distance should have 0 build cost.
# ~300 districts that are in your model with ~1 unscalable campus but the only campuses in that district returned 0 distance.
# however, when you submit them to costquest, they return a build cost. i don't think we always want to assume the build cost is 0 because the distance is 0;
#in some instances, the distance along a road just isnt able to be calculated.
campus_build_costs_pop['max_total_cost'] = where(	campus_build_costs_pop['distance']==0,
													0,
													campus_build_costs_pop['max_build_cost']*campus_build_costs_pop['build_fraction']*cost_magnifier)
campus_build_costs_pop.max_total_cost = campus_build_costs_pop.max_total_cost.round(decimals = 2)
campus_build_costs_pop['max_discount_erate_funding'] = campus_build_costs_pop['max_total_cost']*campus_build_costs_pop['c1_discount_rate_or_state_avg']
campus_build_costs_pop.max_discount_erate_funding = campus_build_costs_pop.max_discount_erate_funding.round(decimals = 2)
campus_build_costs_pop['max_total_state_funding'] = campus_build_costs_pop['max_total_cost']*campus_build_costs_pop['state_match_rate']
campus_build_costs_pop.max_total_state_funding = campus_build_costs_pop.max_total_state_funding.round(decimals = 2)
campus_build_costs_pop['max_total_erate_funding'] = campus_build_costs_pop['max_total_state_funding']+campus_build_costs_pop['max_discount_erate_funding']
campus_build_costs_pop['max_total_district_funding'] = campus_build_costs_pop['max_total_cost']-campus_build_costs_pop['max_total_erate_funding']-campus_build_costs_pop['max_total_state_funding']
campus_build_costs_pop['max_total_district_funding'] = where(	(campus_build_costs_pop.max_total_district_funding.round(decimals=2)>=-.01) & (campus_build_costs_pop.max_total_district_funding.round(decimals=2)<=.01),
																0,
																campus_build_costs_pop['max_total_district_funding'])


campus_build_costs_pop.to_csv('campus_costs_2_10.csv')
#campus_build_costs_pop.to_csv('campus_costs.csv')
print("File saved")