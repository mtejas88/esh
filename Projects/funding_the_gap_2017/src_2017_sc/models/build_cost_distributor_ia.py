from pandas import read_csv, concat
from numpy import where

import os
#from dotenv import load_dotenv, find_dotenv
#load_dotenv(find_dotenv())

import sys
sys.path.insert(0, '/home/sat/sat_r_programs/funding_the_gap/src/features')

from classes import cost_magnifier

unscalable_districts = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/unscalable_districts.csv',index_col=0)
district_costs = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/district_costs.csv',index_col=0)
print("Distrct costs imported")

district_build_costs = concat([unscalable_districts, district_costs], axis=1)
print("Campuses costs range calculated")

district_build_costs['state_match_rate'] = where(	district_build_costs['c1_discount_rate_or_state_avg']>.8,
													(1-district_build_costs['c1_discount_rate_or_state_avg'])/2,
													.1)

##distribute IA costs
district_build_costs['total_cost_ia'] = district_build_costs['district_build_cost']*district_build_costs['build_fraction_ia']*cost_magnifier
district_build_costs.total_cost_ia = district_build_costs.total_cost_ia.round(decimals = 2)
district_build_costs['discount_erate_funding_ia'] = district_build_costs['total_cost_ia']*district_build_costs['c1_discount_rate_or_state_avg']
district_build_costs.discount_erate_funding_ia = district_build_costs.discount_erate_funding_ia.round(decimals = 2)
district_build_costs['total_state_funding_ia'] = district_build_costs['total_cost_ia']*district_build_costs['state_match_rate']
district_build_costs.total_state_funding_ia = district_build_costs.total_state_funding_ia.round(decimals = 2)
district_build_costs['total_erate_funding_ia'] = district_build_costs['total_state_funding_ia']+district_build_costs['discount_erate_funding_ia']
district_build_costs['total_district_funding_ia'] = district_build_costs['total_cost_ia']-district_build_costs['total_erate_funding_ia']-district_build_costs['total_state_funding_ia']
district_build_costs['total_district_funding_ia'] = where(	(district_build_costs.total_district_funding_ia.round(decimals=2)>=-.01) &
																(district_build_costs.total_district_funding_ia.round(decimals=2)<=.01),
															0,
															district_build_costs['total_district_funding_ia'])

district_build_costs.to_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/interim/district_build_costs.csv')
print("File saved")
