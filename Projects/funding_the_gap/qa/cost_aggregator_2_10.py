from pandas import DataFrame, merge, read_csv
from numpy import NaN

#choose one or the other for 1: rerunning 2: static 3:FTG
#from unscalable_districts import districts
#districts = read_csv('districts.csv')
districts = read_csv('districts_new_model_v2.csv')
print("Districts imported")

#determine number of campuses in clean districts for extrapolation
state_clean = districts.loc[districts['denomination'].isin(['1: Fit for FTG, Target', '2: Fit for FTG, Not Target'])]
state_clean = state_clean.loc[state_clean['district_exclude_from_ia_analysis'] == False]
state_clean = state_clean.groupby(['district_postal_cd']).sum()
state_clean['clean_num_campuses'] = state_clean['district_num_campuses']
state_clean = state_clean[['clean_num_campuses']]
state_clean = state_clean.reset_index()

#determine number of campuses that need extrapolation
state_extrapolate = districts.loc[districts['denomination'] == '3: Not Fit for FTG']
state_extrapolate = state_extrapolate.groupby(['district_postal_cd']).sum()
state_extrapolate['extrapolate_num_campuses'] = state_extrapolate['district_num_campuses']
state_extrapolate = state_extrapolate[['extrapolate_num_campuses']]
state_extrapolate = state_extrapolate.reset_index()

#join number of campuses
state_metrics = merge(state_extrapolate, state_clean, how='outer', on='district_postal_cd')
state_metrics['extrapolation'] = (state_metrics['clean_num_campuses'] + state_metrics['extrapolate_num_campuses'])/state_metrics['clean_num_campuses']
state_metrics['extrapolation'] = state_metrics.extrapolation.replace(NaN, 1)

#choose one or the other for 1: rerunning 2: static 3:FTG
#from wan_build_cost_calculator import campus_costs
#campus_costs = read_csv('campus_costs.csv')
#campus_costs = read_csv('campus_costs_new_model_v2.csv')
campus_costs = read_csv('campus_costs_new_model_2_10.csv')
print("Campus costs imported")

#determine cost amounts
state_wan_costs = campus_costs.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()
state_wan_costs = state_wan_costs[[	'min_total_cost', 'min_discount_erate_funding', 'min_total_state_funding', 'min_total_erate_funding', 'min_total_district_funding',
									'max_total_cost', 'max_discount_erate_funding', 'max_total_state_funding', 'max_total_erate_funding', 'max_total_district_funding']]

state_wan_costs = state_wan_costs.reset_index()

#determine clean cost amounts for extrapolation and extrapolate
state_clean_wan_costs = state_wan_costs.loc[state_wan_costs['district_exclude_from_ia_analysis'] == False]
state_metrics = merge(state_metrics, state_clean_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_min_total_cost'] = state_metrics['min_total_cost'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_discount_erate_funding'] = state_metrics['min_discount_erate_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_state_funding'] = state_metrics['min_total_state_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_erate_funding'] = state_metrics['min_total_erate_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_district_funding'] = state_metrics['min_total_district_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_cost'] = state_metrics['max_total_cost'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_discount_erate_funding'] = state_metrics['max_discount_erate_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_state_funding'] = state_metrics['max_total_state_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_erate_funding'] = state_metrics['max_total_erate_funding'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_district_funding'] = state_metrics['max_total_district_funding'] * state_metrics['extrapolation']

#determine dirty cost amounts for and add to extrapolation
state_dirty_wan_costs = state_wan_costs.loc[state_wan_costs['district_exclude_from_ia_analysis'] == True]

state_metrics = merge(state_metrics, state_dirty_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_min_total_cost'] = state_metrics['extrapolated_min_total_cost'].replace(NaN, 0) + state_metrics['min_total_cost_y'].replace(NaN, 0)
state_metrics['extrapolated_min_discount_erate_funding'] = state_metrics['extrapolated_min_discount_erate_funding'].replace(NaN, 0) + state_metrics['min_discount_erate_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_state_funding'] = state_metrics['extrapolated_min_total_state_funding'].replace(NaN, 0) + state_metrics['min_total_state_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_erate_funding'] = state_metrics['extrapolated_min_total_erate_funding'].replace(NaN, 0) + state_metrics['min_total_erate_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_district_funding'] = 	state_metrics['extrapolated_min_total_district_funding'].replace(NaN, 0) + state_metrics['min_total_district_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_cost'] = state_metrics['extrapolated_max_total_cost'].replace(NaN, 0) + state_metrics['max_total_cost_y'].replace(NaN, 0)
state_metrics['extrapolated_max_discount_erate_funding'] = state_metrics['extrapolated_max_discount_erate_funding'].replace(NaN, 0) + state_metrics['max_discount_erate_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_state_funding'] = state_metrics['extrapolated_max_total_state_funding'].replace(NaN, 0) + state_metrics['max_total_state_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_erate_funding'] = state_metrics['extrapolated_max_total_erate_funding'].replace(NaN, 0) + state_metrics['max_total_erate_funding_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_district_funding'] = 	state_metrics['extrapolated_max_total_district_funding'].replace(NaN, 0) + state_metrics['max_total_district_funding_y'].replace(NaN, 0)


#state_metrics.to_csv('state_metrics.csv')
#state_metrics.to_csv('state_metrics_v2.csv')
state_metrics.to_csv('state_metrics_new_model_2_10.csv')