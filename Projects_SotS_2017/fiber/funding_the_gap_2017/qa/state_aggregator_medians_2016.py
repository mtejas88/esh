from pandas import DataFrame, merge, read_csv
from numpy import NaN, where, logical_or

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")


districts = read_csv(GITHUB+'/Projects/funding_the_gap/data/interim/districts.csv')
print("Districts imported")
state_extrapolations = read_csv(GITHUB+'/Projects/funding_the_gap/data/interim/state_extrapolations.csv')
print("State Extrapolations imported")


##WAN COST

#import campus build costs
campus_build_costs = read_csv(GITHUB+'/Projects_SotS_2017/fiber/funding_the_gap_2017/data/interim/campus_build_costs_16.csv')
print("Campus costs imported")

#determine state cost amounts
state_wan_costs = campus_build_costs.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()
state_wan_costs = state_wan_costs[[	'total_cost_median', 'discount_erate_funding_median', 'total_state_funding_median', 'total_erate_funding_median','total_district_funding_median']]
state_wan_costs = state_wan_costs.reset_index()

#determine clean cost amounts for extrapolation and extrapolate -- min / max / a-->z / a-->pop-->z
state_clean_wan_costs = state_wan_costs[state_wan_costs['district_exclude_from_ia_analysis'] == False]
state_metrics = merge(state_extrapolations, state_clean_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_total_cost_median_wan'] = state_metrics['total_cost_median'] * state_metrics['extrapolation']
state_metrics['extrapolated_discount_erate_funding_median_wan'] = state_metrics['discount_erate_funding_median'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_state_funding_median_wan'] = state_metrics['total_state_funding_median'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_erate_funding_median_wan'] = state_metrics['total_erate_funding_median'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_district_funding_median_wan'] = state_metrics['total_district_funding_median'] * state_metrics['extrapolation']

#determine dirty cost amounts for and add to extrapolation -- min / max / a-->z / a-->pop-->z
state_dirty_wan_costs = state_wan_costs[state_wan_costs['district_exclude_from_ia_analysis'] == True]
state_metrics = merge(state_metrics, state_dirty_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_total_cost_median_wan'] = state_metrics['extrapolated_total_cost_median_wan'].replace(NaN, 0) + state_metrics['total_cost_median_y'].replace(NaN, 0)
state_metrics['extrapolated_discount_erate_funding_median_wan'] = state_metrics['extrapolated_discount_erate_funding_median_wan'].replace(NaN, 0) + state_metrics['discount_erate_funding_median_y'].replace(NaN, 0)
state_metrics['extrapolated_total_state_funding_median_wan'] = state_metrics['extrapolated_total_state_funding_median_wan'].replace(NaN, 0) + state_metrics['total_state_funding_median_y'].replace(NaN, 0)
state_metrics['extrapolated_total_erate_funding_median_wan'] = state_metrics['extrapolated_total_erate_funding_median_wan'].replace(NaN, 0) + state_metrics['total_erate_funding_median_y'].replace(NaN, 0)
state_metrics['extrapolated_total_district_funding_median_wan'] = 	state_metrics['extrapolated_total_district_funding_median_wan'].replace(NaN, 0) + state_metrics['total_district_funding_median_y'].replace(NaN, 0)

print("Campus costs extrapolated")

##IA COST

#import district build costs
district_build_costs = read_csv(GITHUB+'/Projects/funding_the_gap/data/interim/district_build_costs.csv')
print("District costs imported")

#determine cost amounts
state_ia_costs = district_build_costs.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()
state_ia_costs = state_ia_costs[[	'total_cost_ia', 'discount_erate_funding_ia', 'total_state_funding_ia', 'total_erate_funding_ia', 'total_district_funding_ia',
									'build_fraction_ia', 'district_build_distance']]
state_ia_costs = state_ia_costs.reset_index()

#determine clean cost amounts for extrapolation  and extrapolate
state_clean_ia_costs = state_ia_costs[state_ia_costs['district_exclude_from_ia_analysis'] == False]
state_metrics = merge(state_metrics, state_clean_ia_costs, how='outer', on='district_postal_cd')

#determine median extrapolation factor
state_metrics['extrapolation_median'] = state_metrics[["extrapolation", "extrapolation_orig"]].mean(axis=1)


#extrapolate for clean only for orig, and add back in dirtys for not_orig. min and max needs to be done after
state_metrics['extrapolated_total_cost_ia'] = state_metrics['total_cost_ia'] * state_metrics['extrapolation_median']
state_metrics['extrapolated_discount_erate_funding_ia'] = state_metrics['discount_erate_funding_ia'] * state_metrics['extrapolation_median']
state_metrics['extrapolated_total_state_funding_ia'] = state_metrics['total_state_funding_ia'] * state_metrics['extrapolation_median']
state_metrics['extrapolated_total_erate_funding_ia'] = state_metrics['total_erate_funding_ia'] * state_metrics['extrapolation_median']
state_metrics['extrapolated_total_district_funding_ia'] = state_metrics['total_district_funding_ia'] * state_metrics['extrapolation_median']

#determine dirty cost amounts for and add to extrapolation
state_dirty_ia_costs = state_ia_costs[state_wan_costs['district_exclude_from_ia_analysis'] == True]

state_metrics = merge(state_metrics, state_dirty_ia_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_total_cost_ia'] = state_metrics['extrapolated_total_cost_ia'].replace(NaN, 0) + state_metrics['total_cost_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_discount_erate_funding_ia'] = state_metrics['extrapolated_discount_erate_funding_ia'].replace(NaN, 0) + state_metrics['discount_erate_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_state_funding_ia'] = state_metrics['extrapolated_total_state_funding_ia'].replace(NaN, 0) + state_metrics['total_state_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_erate_funding_ia'] = state_metrics['extrapolated_total_erate_funding_ia'].replace(NaN, 0) + state_metrics['total_erate_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_district_funding_ia'] = 	state_metrics['extrapolated_total_district_funding_ia'].replace(NaN, 0) + state_metrics['total_district_funding_ia_y'].replace(NaN, 0)
print("District costs extrapolated")

##add IA and WAN costs
#have to multiply all values by 61%. this is the value we had to multiply this methodology by to match the total cost from the 2016 report.
state_metrics['extrapolated_total_cost'] = (state_metrics['extrapolated_total_cost_ia'] + state_metrics['extrapolated_total_cost_median_wan']) * .606
state_metrics['extrapolated_discount_erate_funding'] = (state_metrics['extrapolated_discount_erate_funding_ia'] + state_metrics['extrapolated_discount_erate_funding_median_wan']) * .606
state_metrics['extrapolated_total_state_funding'] = (state_metrics['extrapolated_total_state_funding_ia'] + state_metrics['extrapolated_total_state_funding_median_wan']) * .606
state_metrics['extrapolated_total_erate_funding'] = (state_metrics['extrapolated_total_erate_funding_ia'] + state_metrics['extrapolated_total_erate_funding_median_wan']) * .606
state_metrics['extrapolated_total_district_funding'] = 	(state_metrics['extrapolated_total_district_funding_ia'] + state_metrics['extrapolated_total_district_funding_median_wan']) * .606

state_metrics = state_metrics[[	'district_postal_cd', 'extrapolated_total_cost', 'extrapolated_discount_erate_funding', 'extrapolated_total_state_funding', 'extrapolated_total_erate_funding', 'extrapolated_total_district_funding']]

state_metrics  = state_metrics

state_metrics.to_csv(GITHUB+'/Projects_SotS_2017/fiber/funding_the_gap_2017/data/processed/state_metrics_2016.csv')
print("File saved")


