from pandas import read_csv
from numpy import where

from classes import cost_magnifier


#choose one or the other for 1: rerunning 2: static 3:FTG
#from wan_build_cost_calculator import campus_build_costs
campus_build_costs = read_csv('campus_build_costs.csv')
#campus_build_costs = read_csv('campus_build_costs_new_model_v2.csv')
print("Campuses costs imported")


#to-do: confirm that campuses with 0 distance should have 0 build cost.
# ~300 districts that are in your model with ~1 unscalable campus but the only campuses in that district returned 0 distance.
# however, when you submit them to costquest, they return a build cost. i don't think we always want to assume the build cost is 0 because the distance is 0; in some instances, the distance along a road just isnt able to be calculated.
campus_build_costs['total_cost'] = where(	campus_build_costs['distance']==0,
											0,
											campus_build_costs['build_cost']*campus_build_costs['build_fraction']*cost_magnifier)
campus_build_costs.total_cost = campus_build_costs.total_cost.round(decimals = 2)
campus_build_costs['discount_erate_funding'] = campus_build_costs['total_cost']*campus_build_costs['c1_discount_rate_or_state_avg']
campus_build_costs.discount_erate_funding = campus_build_costs.discount_erate_funding.round(decimals = 2)
campus_build_costs['state_match_rate'] = where(	campus_build_costs['c1_discount_rate_or_state_avg']>.8,
												(1-campus_build_costs['c1_discount_rate_or_state_avg'])/2,
												.1)
campus_build_costs['total_state_funding'] = campus_build_costs['total_cost']*campus_build_costs['state_match_rate']
campus_build_costs.total_state_funding = campus_build_costs.total_state_funding.round(decimals = 2)
campus_build_costs['total_erate_funding'] = campus_build_costs['total_state_funding']+campus_build_costs['discount_erate_funding']
campus_build_costs['total_district_funding'] = campus_build_costs['total_cost']-campus_build_costs['total_erate_funding']-campus_build_costs['total_state_funding']
campus_build_costs['total_district_funding'] = where(	(campus_build_costs.total_district_funding.round(decimals=2)>=-.01) & (campus_build_costs.total_district_funding.round(decimals=2)<=.01),
														0,
														campus_build_costs['total_district_funding'])
#campus_build_costs.to_csv('campus_costs_v2.csv')
campus_build_costs.to_csv('campus_costs.csv')
print("File saved")