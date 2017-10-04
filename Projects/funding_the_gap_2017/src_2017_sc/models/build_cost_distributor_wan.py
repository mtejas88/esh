from pandas import read_csv, concat, merge
from numpy import where

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())

import sys
sys.path.insert(0, '/home/sat/sat_r_programs/funding_the_gap/src/features')


from classes import cost_magnifier

campus_build_costs = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/campus_build_costs_before_distribution.csv',index_col=0)
state_cost_per_mile = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/state_cost_per_mile.csv',index_col=0)
print("Campuses costs imported")

##fill in cost/mile for campuses without cost calculated
campus_build_costs = merge(campus_build_costs, state_cost_per_mile, how='outer', on='district_postal_cd')
campus_build_costs['build_cost_az_pop'] = where(campus_build_costs['build_cost_az_pop']<0,
												campus_build_costs['build_cost_az_pop_per_mile']*campus_build_costs['build_distance_az_pop'],
												campus_build_costs['build_cost_az_pop'])
campus_build_costs['build_cost_az'] = where(	campus_build_costs['build_cost_az']<0,
												campus_build_costs['build_cost_az_per_mile']*campus_build_costs['distance'],
												campus_build_costs['build_cost_az'])

##calculate state match rate
campus_build_costs['state_match_rate'] = where(	campus_build_costs['c1_discount_rate_or_state_avg']>.8,
												(1-campus_build_costs['c1_discount_rate_or_state_avg'])/2,
												.1)

##distribute A-->PoP-->Z WAN costs
campus_build_costs['total_cost_az_pop_wan'] = where(campus_build_costs['distance']==0,
													0,
													campus_build_costs['build_cost_az_pop']*campus_build_costs['build_fraction_wan']*cost_magnifier)
campus_build_costs.total_cost_az_pop_wan = campus_build_costs.total_cost_az_pop_wan.round(decimals = 2)
campus_build_costs['discount_erate_funding_az_pop_wan'] = campus_build_costs['total_cost_az_pop_wan']*campus_build_costs['c1_discount_rate_or_state_avg']
campus_build_costs.discount_erate_funding_az_pop_wan = campus_build_costs.discount_erate_funding_az_pop_wan.round(decimals = 2)
campus_build_costs['total_state_funding_az_pop_wan'] = campus_build_costs['total_cost_az_pop_wan']*campus_build_costs['state_match_rate']
campus_build_costs.total_state_funding_az_pop_wan = campus_build_costs.total_state_funding_az_pop_wan.round(decimals = 2)
campus_build_costs['total_erate_funding_az_pop_wan'] = campus_build_costs['total_state_funding_az_pop_wan']+campus_build_costs['discount_erate_funding_az_pop_wan']
campus_build_costs['total_district_funding_az_pop_wan'] = campus_build_costs['total_cost_az_pop_wan']-campus_build_costs['total_erate_funding_az_pop_wan']-campus_build_costs['total_state_funding_az_pop_wan']
campus_build_costs['total_district_funding_az_pop_wan'] = where((campus_build_costs.total_district_funding_az_pop_wan.round(decimals=2)>=-.01) &
																	(campus_build_costs.total_district_funding_az_pop_wan.round(decimals=2)<=.01),
																0,
																campus_build_costs['total_district_funding_az_pop_wan'])

##distribute A-->Z WAN costs
campus_build_costs['total_cost_az_wan'] = where(campus_build_costs['distance']==0,
												0,
												campus_build_costs['build_cost_az']*campus_build_costs['build_fraction_wan']*cost_magnifier)
campus_build_costs.total_cost_az_wan = campus_build_costs.total_cost_az_wan.round(decimals = 2)
campus_build_costs['discount_erate_funding_az_wan'] = campus_build_costs['total_cost_az_wan']*campus_build_costs['c1_discount_rate_or_state_avg']
campus_build_costs.discount_erate_funding_az_wan = campus_build_costs.discount_erate_funding_az_wan.round(decimals = 2)
campus_build_costs['total_state_funding_az_wan'] = campus_build_costs['total_cost_az_wan']*campus_build_costs['state_match_rate']
campus_build_costs.total_state_funding_az_wan = campus_build_costs.total_state_funding_az_wan.round(decimals = 2)
campus_build_costs['total_erate_funding_az_wan'] = campus_build_costs['total_state_funding_az_wan']+campus_build_costs['discount_erate_funding_az_wan']
campus_build_costs['total_district_funding_az_wan'] = campus_build_costs['total_cost_az_wan']-campus_build_costs['total_erate_funding_az_wan']-campus_build_costs['total_state_funding_az_wan']
campus_build_costs['total_district_funding_az_wan'] = where((	campus_build_costs.total_district_funding_az_wan.round(decimals=2)>=-.01) &
																	(campus_build_costs.total_district_funding_az_wan.round(decimals=2)<=.01),
																0,
																campus_build_costs['total_district_funding_az_wan'])

campus_build_costs['az_min']= where( campus_build_costs['total_cost_az_wan'] <= campus_build_costs['total_cost_az_pop_wan'],1,0)
campus_build_costs.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/campus_build_costs.csv')
print("File saved")
