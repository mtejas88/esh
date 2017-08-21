from pandas import DataFrame, merge, read_csv
from numpy import NaN, where, logical_or

districts = read_csv('../../data/interim/districts.csv')
print("Districts imported")

##EXTRAPOLATION

#determine number of campuses in clean districts for extrapolation
state_clean = districts[districts['denomination'].isin(['1: Fit for FTG, Target', '2: Fit for FTG, Not Target'])]
state_clean = state_clean[state_clean['district_exclude_from_ia_analysis'] == False]
state_clean = state_clean.groupby(['district_postal_cd']).sum()
state_clean['clean_num_campuses'] = state_clean['district_num_campuses']
state_clean = state_clean[['clean_num_campuses']]
state_clean = state_clean.reset_index()

#determine number of campuses that need extrapolation
state_extrapolate = districts[districts['denomination'] == '3: Not Fit for FTG']
state_extrapolate = state_extrapolate.groupby(['district_postal_cd']).sum()
state_extrapolate['extrapolate_num_campuses'] = state_extrapolate['district_num_campuses']
state_extrapolate = state_extrapolate[['extrapolate_num_campuses']]
state_extrapolate = state_extrapolate.reset_index()

#join number of campuses
state_metrics = merge(state_extrapolate, state_clean, how='outer', on='district_postal_cd')
state_metrics['extrapolation'] = (state_metrics['clean_num_campuses'] + state_metrics['extrapolate_num_campuses'])/state_metrics['clean_num_campuses']
state_metrics['extrapolation'] = state_metrics.extrapolation.replace(NaN, 1)

##ORIG EXTRAPOLATION

#determine number of campuses in clean districts for original extrapolation
state_clean_orig = districts[districts['district_exclude_from_ia_analysis'] == False]
state_clean_orig = state_clean_orig.groupby(['district_postal_cd']).sum()
state_clean_orig['clean_orig_num_campuses'] = state_clean_orig['district_num_campuses']
state_clean_orig = state_clean_orig[['clean_orig_num_campuses']]
state_clean_orig = state_clean_orig.reset_index()

#determine number of campuses that need original extrapolation
state_extrapolate_orig = districts[districts['district_exclude_from_ia_analysis'] == True]
state_extrapolate_orig = state_extrapolate_orig.groupby(['district_postal_cd']).sum()
state_extrapolate_orig['extrapolate_orig_num_campuses'] = state_extrapolate_orig['district_num_campuses']
state_extrapolate_orig = state_extrapolate_orig[['extrapolate_orig_num_campuses']]
state_extrapolate_orig = state_extrapolate_orig.reset_index()

#join number of campuses or original extrapolation
state_metrics_orig = merge(state_extrapolate_orig, state_clean_orig, how='outer', on='district_postal_cd')
state_metrics_orig['extrapolation_orig'] = (state_metrics_orig['clean_orig_num_campuses'] + state_metrics_orig['extrapolate_orig_num_campuses'])/state_metrics_orig['clean_orig_num_campuses']
state_metrics_orig['extrapolation_orig'] = state_metrics_orig.extrapolation_orig.replace(NaN, 1)

#combine extrapolations
state_metrics = merge(state_metrics_orig, state_metrics, how='outer', on='district_postal_cd')
print("Extrapolations calculated")

state_metrics.to_csv('../../data/interim/state_extrapolations.csv')
##WAN COST

#import campus build costs
campus_build_costs = read_csv('../../data/interim/campus_build_costs.csv')
print("Campus costs imported")

#determine min and max values
campus_build_costs['min_total_cost_wan'] = campus_build_costs[['total_cost_az_pop_wan', 'total_cost_az_wan']].min(axis=1)
campus_build_costs['min_discount_erate_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
																campus_build_costs['discount_erate_funding_az_pop_wan'],
																campus_build_costs['discount_erate_funding_az_wan'])
campus_build_costs['min_total_state_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
															campus_build_costs['total_state_funding_az_pop_wan'],
															campus_build_costs['total_state_funding_az_wan'])
campus_build_costs['min_total_erate_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
															campus_build_costs['total_erate_funding_az_pop_wan'],
															campus_build_costs['total_erate_funding_az_wan'])
campus_build_costs['min_total_district_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
																campus_build_costs['total_district_funding_az_pop_wan'],
																campus_build_costs['total_district_funding_az_wan'])
campus_build_costs['min_builds_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
														2,
														1) * campus_build_costs['build_fraction_wan']
campus_build_costs['min_build_distance_wan'] = where(	campus_build_costs['total_cost_az_wan']>campus_build_costs['total_cost_az_pop_wan'],
														campus_build_costs['build_distance_az_pop'] * campus_build_costs['build_fraction_wan'],
														campus_build_costs['distance'] * campus_build_costs['build_fraction_wan'])
campus_build_costs['max_total_cost_wan'] = campus_build_costs[['total_cost_az_pop_wan', 'total_cost_az_wan']].max(axis=1)
campus_build_costs['max_discount_erate_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
																campus_build_costs['discount_erate_funding_az_pop_wan'],
																campus_build_costs['discount_erate_funding_az_wan'])
campus_build_costs['max_total_state_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
															campus_build_costs['total_state_funding_az_pop_wan'],
															campus_build_costs['total_state_funding_az_wan'])
campus_build_costs['max_total_erate_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
															campus_build_costs['total_erate_funding_az_pop_wan'],
															campus_build_costs['total_erate_funding_az_wan'])
campus_build_costs['max_total_district_funding_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
																campus_build_costs['total_district_funding_az_pop_wan'],
																campus_build_costs['total_district_funding_az_wan'])
campus_build_costs['max_builds_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
														2,
														1) * campus_build_costs['build_fraction_wan']
campus_build_costs['max_build_distance_wan'] = where(	campus_build_costs['total_cost_az_wan']<=campus_build_costs['total_cost_az_pop_wan'],
														campus_build_costs['build_distance_az_pop'] * campus_build_costs['build_fraction_wan'],
														campus_build_costs['distance'] * campus_build_costs['build_fraction_wan'])

#create factors for a-->z and a-->pop-->z aggregation
campus_build_costs['builds_az_pop_wan'] = 2 * campus_build_costs['build_fraction_wan']
campus_build_costs['build_distance_az_wan'] = campus_build_costs['distance'] * campus_build_costs['build_fraction_wan']
campus_build_costs['build_distance_az_pop_wan'] = campus_build_costs['build_distance_az_pop'] * campus_build_costs['build_fraction_wan']


#determine state cost amounts
state_wan_costs = campus_build_costs.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()
state_wan_costs = state_wan_costs[[	'min_total_cost_wan', 'min_discount_erate_funding_wan', 'min_total_state_funding_wan', 'min_total_erate_funding_wan',
									'min_total_district_funding_wan', 'min_builds_wan', 'min_build_distance_wan',
									'max_total_cost_wan', 'max_discount_erate_funding_wan', 'max_total_state_funding_wan', 'max_total_erate_funding_wan',
									'max_total_district_funding_wan',  'max_builds_wan', 'max_build_distance_wan',
									'total_cost_az_wan', 'discount_erate_funding_az_wan', 'total_state_funding_az_wan', 'total_erate_funding_az_wan',
									'total_district_funding_az_wan',  'build_fraction_wan', 'build_distance_az_wan',
									'total_cost_az_pop_wan', 'discount_erate_funding_az_pop_wan', 'total_state_funding_az_pop_wan', 'total_erate_funding_az_pop_wan',
									'total_district_funding_az_pop_wan',  'builds_az_pop_wan', 'build_distance_az_pop_wan']]
state_wan_costs = state_wan_costs.reset_index()

#determine clean cost amounts for extrapolation and extrapolate -- min / max / a-->z / a-->pop-->z
state_clean_wan_costs = state_wan_costs[state_wan_costs['district_exclude_from_ia_analysis'] == False]
state_metrics = merge(state_metrics, state_clean_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_min_total_cost_wan'] = state_metrics['min_total_cost_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_discount_erate_funding_wan'] = state_metrics['min_discount_erate_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_state_funding_wan'] = state_metrics['min_total_state_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_erate_funding_wan'] = state_metrics['min_total_erate_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_total_district_funding_wan'] = state_metrics['min_total_district_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_builds_wan'] = state_metrics['min_builds_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_min_build_distance_wan'] = state_metrics['min_build_distance_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_cost_wan'] = state_metrics['max_total_cost_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_discount_erate_funding_wan'] = state_metrics['max_discount_erate_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_state_funding_wan'] = state_metrics['max_total_state_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_erate_funding_wan'] = state_metrics['max_total_erate_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_total_district_funding_wan'] = state_metrics['max_total_district_funding_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_builds_wan'] = state_metrics['max_builds_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_max_build_distance_wan'] = state_metrics['max_build_distance_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_cost_az_wan'] = state_metrics['total_cost_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_discount_erate_funding_az_wan'] = state_metrics['discount_erate_funding_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_state_funding_az_wan'] = state_metrics['total_state_funding_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_erate_funding_az_wan'] = state_metrics['total_erate_funding_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_district_funding_az_wan'] = state_metrics['total_district_funding_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_builds_az_wan'] = state_metrics['build_fraction_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_build_distance_az_wan'] = state_metrics['build_distance_az_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_cost_az_pop_wan'] = state_metrics['total_cost_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_discount_erate_funding_az_pop_wan'] = state_metrics['discount_erate_funding_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_state_funding_az_pop_wan'] = state_metrics['total_state_funding_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_erate_funding_az_pop_wan'] = state_metrics['total_erate_funding_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_district_funding_az_pop_wan'] = state_metrics['total_district_funding_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_builds_az_pop_wan'] = state_metrics['builds_az_pop_wan'] * state_metrics['extrapolation']
state_metrics['extrapolated_build_distance_az_pop_wan'] = state_metrics['build_distance_az_pop_wan'] * state_metrics['extrapolation']

#determine dirty cost amounts for and add to extrapolation -- min / max / a-->z / a-->pop-->z
state_dirty_wan_costs = state_wan_costs[state_wan_costs['district_exclude_from_ia_analysis'] == True]
state_metrics = merge(state_metrics, state_dirty_wan_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_min_total_cost_wan'] = state_metrics['extrapolated_min_total_cost_wan'].replace(NaN, 0) + state_metrics['min_total_cost_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_min_discount_erate_funding_wan'] = state_metrics['extrapolated_min_discount_erate_funding_wan'].replace(NaN, 0) + state_metrics['min_discount_erate_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_state_funding_wan'] = state_metrics['extrapolated_min_total_state_funding_wan'].replace(NaN, 0) + state_metrics['min_total_state_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_erate_funding_wan'] = state_metrics['extrapolated_min_total_erate_funding_wan'].replace(NaN, 0) + state_metrics['min_total_erate_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_min_total_district_funding_wan'] = 	state_metrics['extrapolated_min_total_district_funding_wan'].replace(NaN, 0) + state_metrics['min_total_district_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_min_builds_wan'] = 	state_metrics['extrapolated_min_builds_wan'].replace(NaN, 0) + (state_metrics['min_builds_wan_y'].replace(NaN, 0) * 2)
state_metrics['extrapolated_min_build_distance_wan'] = 	state_metrics['extrapolated_min_build_distance_wan'].replace(NaN, 0) + state_metrics['min_build_distance_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_cost_wan'] = state_metrics['extrapolated_max_total_cost_wan'].replace(NaN, 0) + state_metrics['max_total_cost_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_discount_erate_funding_wan'] = state_metrics['extrapolated_max_discount_erate_funding_wan'].replace(NaN, 0) + state_metrics['max_discount_erate_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_state_funding_wan'] = state_metrics['extrapolated_max_total_state_funding_wan'].replace(NaN, 0) + state_metrics['max_total_state_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_erate_funding_wan'] = state_metrics['extrapolated_max_total_erate_funding_wan'].replace(NaN, 0) + state_metrics['max_total_erate_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_total_district_funding_wan'] = 	state_metrics['extrapolated_max_total_district_funding_wan'].replace(NaN, 0) + state_metrics['max_total_district_funding_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_max_builds_wan'] = 	state_metrics['extrapolated_max_builds_wan'].replace(NaN, 0) + (state_metrics['max_builds_wan_y'].replace(NaN, 0) * 2)
state_metrics['extrapolated_max_build_distance_wan'] = 	state_metrics['extrapolated_max_build_distance_wan'].replace(NaN, 0) + state_metrics['max_build_distance_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_cost_az_wan'] = state_metrics['extrapolated_total_cost_az_wan'].replace(NaN, 0) + state_metrics['total_cost_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_discount_erate_funding_az_wan'] = state_metrics['extrapolated_discount_erate_funding_az_wan'].replace(NaN, 0) + state_metrics['discount_erate_funding_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_state_funding_az_wan'] = state_metrics['extrapolated_total_state_funding_az_wan'].replace(NaN, 0) + state_metrics['total_state_funding_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_erate_funding_az_wan'] = state_metrics['extrapolated_total_erate_funding_az_wan'].replace(NaN, 0) + state_metrics['total_erate_funding_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_district_funding_az_wan'] = 	state_metrics['extrapolated_total_district_funding_az_wan'].replace(NaN, 0) + state_metrics['total_district_funding_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_builds_az_wan'] = state_metrics['extrapolated_builds_az_wan'].replace(NaN, 0) + state_metrics['build_fraction_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_build_distance_az_wan'] = 	state_metrics['extrapolated_build_distance_az_wan'].replace(NaN, 0) + state_metrics['build_distance_az_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_cost_az_pop_wan'] = state_metrics['extrapolated_total_cost_az_pop_wan'].replace(NaN, 0) + state_metrics['total_cost_az_pop_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_discount_erate_funding_az_pop_wan'] = state_metrics['extrapolated_discount_erate_funding_az_pop_wan'].replace(NaN, 0) + state_metrics['discount_erate_funding_az_pop_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_state_funding_az_pop_wan'] = state_metrics['extrapolated_total_state_funding_az_pop_wan'].replace(NaN, 0) + state_metrics['total_state_funding_az_pop_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_erate_funding_az_pop_wan'] = state_metrics['extrapolated_total_erate_funding_az_pop_wan'].replace(NaN, 0) + state_metrics['total_erate_funding_az_pop_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_total_district_funding_az_pop_wan'] = 	state_metrics['extrapolated_total_district_funding_az_pop_wan'].replace(NaN, 0) + state_metrics['total_district_funding_az_pop_wan_y'].replace(NaN, 0)
state_metrics['extrapolated_builds_az_pop_wan'] = 	state_metrics['extrapolated_builds_az_pop_wan'].replace(NaN, 0) + (state_metrics['builds_az_pop_wan_y'].replace(NaN, 0) * 2)
state_metrics['extrapolated_build_distance_az_pop_wan'] = 	state_metrics['extrapolated_build_distance_az_pop_wan'].replace(NaN, 0) + state_metrics['build_distance_az_pop_wan_y'].replace(NaN, 0)

print("Campus costs extrapolated")

##IA COST

#import district build costs
district_build_costs = read_csv('../../data/interim/district_build_costs.csv')
print("District costs imported")

#determine cost amounts
state_ia_costs = district_build_costs.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()
state_ia_costs = state_ia_costs[[	'total_cost_ia', 'discount_erate_funding_ia', 'total_state_funding_ia', 'total_erate_funding_ia', 'total_district_funding_ia',
									'build_fraction_ia', 'district_build_distance']]
state_ia_costs = state_ia_costs.reset_index()

#determine clean cost amounts for extrapolation  and extrapolate
state_clean_ia_costs = state_ia_costs[state_ia_costs['district_exclude_from_ia_analysis'] == False]
state_metrics = merge(state_metrics, state_clean_ia_costs, how='outer', on='district_postal_cd')

#extrapolate for clean only for orig, and add back in dirtys for not_orig. min and max needs to be done after
state_metrics['extrapolated_total_cost_ia'] = state_metrics['total_cost_ia'] * state_metrics['extrapolation']
state_metrics['extrapolated_discount_erate_funding_ia'] = state_metrics['discount_erate_funding_ia'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_state_funding_ia'] = state_metrics['total_state_funding_ia'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_erate_funding_ia'] = state_metrics['total_erate_funding_ia'] * state_metrics['extrapolation']
state_metrics['extrapolated_total_district_funding_ia'] = state_metrics['total_district_funding_ia'] * state_metrics['extrapolation']
state_metrics['extrapolated_builds_ia'] = state_metrics['build_fraction_ia'].replace(NaN, 0) * state_metrics['extrapolation']
state_metrics['extrapolated_build_distance_ia'] = state_metrics['district_build_distance'].replace(NaN, 0) * state_metrics['extrapolation']
state_metrics['extrapolated_orig_total_cost_ia'] = state_metrics['total_cost_ia'] * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_discount_erate_funding_ia'] = state_metrics['discount_erate_funding_ia'] * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_total_state_funding_ia'] = state_metrics['total_state_funding_ia'] * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_total_erate_funding_ia'] = state_metrics['total_erate_funding_ia'] * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_total_district_funding_ia'] = state_metrics['total_district_funding_ia'] * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_builds_ia'] = state_metrics['build_fraction_ia'].replace(NaN, 0) * state_metrics['extrapolation_orig']
state_metrics['extrapolated_orig_build_distance_ia'] = state_metrics['district_build_distance'].replace(NaN, 0) * state_metrics['extrapolation_orig']

#determine dirty cost amounts for and add to extrapolation
state_dirty_ia_costs = state_ia_costs[state_wan_costs['district_exclude_from_ia_analysis'] == True]

state_metrics = merge(state_metrics, state_dirty_ia_costs, how='outer', on='district_postal_cd')
state_metrics['extrapolated_total_cost_ia'] = state_metrics['extrapolated_total_cost_ia'].replace(NaN, 0) + state_metrics['total_cost_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_discount_erate_funding_ia'] = state_metrics['extrapolated_discount_erate_funding_ia'].replace(NaN, 0) + state_metrics['discount_erate_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_state_funding_ia'] = state_metrics['extrapolated_total_state_funding_ia'].replace(NaN, 0) + state_metrics['total_state_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_erate_funding_ia'] = state_metrics['extrapolated_total_erate_funding_ia'].replace(NaN, 0) + state_metrics['total_erate_funding_ia_y'].replace(NaN, 0)
state_metrics['extrapolated_total_district_funding_ia'] = 	state_metrics['extrapolated_total_district_funding_ia'].replace(NaN, 0) + state_metrics['total_district_funding_ia_y'].replace(NaN, 0)
print("District costs extrapolated")

#take min and max
state_metrics['extrapolated_min_total_cost_ia'] = state_metrics[['extrapolated_total_cost_ia', 'extrapolated_orig_total_cost_ia']].min(axis=1)
state_metrics['extrapolated_min_discount_erate_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_discount_erate_funding_ia'],
																	state_metrics['extrapolated_discount_erate_funding_ia'])
state_metrics['extrapolated_min_total_state_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_state_funding_ia'],
																	state_metrics['extrapolated_total_state_funding_ia'])
state_metrics['extrapolated_min_total_erate_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_erate_funding_ia'],
																	state_metrics['extrapolated_total_erate_funding_ia'])
state_metrics['extrapolated_min_total_district_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_district_funding_ia'],
																	state_metrics['extrapolated_total_district_funding_ia'])
state_metrics['extrapolated_min_builds_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_builds_ia'],
																	state_metrics['extrapolated_builds_ia'])
state_metrics['extrapolated_min_build_distance_ia'] = where(state_metrics['extrapolated_total_cost_ia']>state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_build_distance_ia'],
																	state_metrics['extrapolated_build_distance_ia'])
state_metrics['extrapolated_max_total_cost_ia'] = state_metrics[['extrapolated_total_cost_ia', 'extrapolated_orig_total_cost_ia']].max(axis=1)
state_metrics['extrapolated_max_discount_erate_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_discount_erate_funding_ia'],
																	state_metrics['extrapolated_discount_erate_funding_ia'])
state_metrics['extrapolated_max_total_state_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_state_funding_ia'],
																	state_metrics['extrapolated_total_state_funding_ia'])
state_metrics['extrapolated_max_total_erate_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_erate_funding_ia'],
																	state_metrics['extrapolated_total_erate_funding_ia'])
state_metrics['extrapolated_max_total_district_funding_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_total_district_funding_ia'],
																	state_metrics['extrapolated_total_district_funding_ia'])
state_metrics['extrapolated_max_builds_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_builds_ia'],
																	state_metrics['extrapolated_builds_ia'])
state_metrics['extrapolated_max_build_distance_ia'] = where(state_metrics['extrapolated_total_cost_ia']<=state_metrics['extrapolated_orig_total_cost_ia'],
																	state_metrics['extrapolated_orig_build_distance_ia'],
																	state_metrics['extrapolated_build_distance_ia'])

#add IA and WAN costs
state_metrics['extrapolated_min_total_cost'] = state_metrics['extrapolated_min_total_cost_ia'] + state_metrics['extrapolated_min_total_cost_wan']
state_metrics['extrapolated_min_discount_erate_funding'] = state_metrics['extrapolated_min_discount_erate_funding_ia'] + state_metrics['extrapolated_min_discount_erate_funding_wan']
state_metrics['extrapolated_min_total_state_funding'] = state_metrics['extrapolated_min_total_state_funding_ia'] + state_metrics['extrapolated_min_total_state_funding_wan']
state_metrics['extrapolated_min_total_erate_funding'] = state_metrics['extrapolated_min_total_erate_funding_ia'] + state_metrics['extrapolated_min_total_erate_funding_wan']
state_metrics['extrapolated_min_total_district_funding'] = 	state_metrics['extrapolated_min_total_district_funding_ia'] + state_metrics['extrapolated_min_total_district_funding_wan']
state_metrics['extrapolated_min_builds'] = 	state_metrics['extrapolated_min_builds_ia'] + state_metrics['extrapolated_min_builds_wan']
state_metrics['extrapolated_min_build_distance'] = 	state_metrics['extrapolated_min_build_distance_ia'] + state_metrics['extrapolated_min_build_distance_wan']
state_metrics['min_total_cost_per_mile'] = 	state_metrics['extrapolated_min_total_cost'] / state_metrics['extrapolated_min_build_distance']
state_metrics['min_miles_per_build'] = 	state_metrics['extrapolated_min_build_distance'] / state_metrics['extrapolated_min_builds']

state_metrics['extrapolated_max_total_cost'] = state_metrics['extrapolated_max_total_cost_ia'] + state_metrics['extrapolated_max_total_cost_wan']
state_metrics['extrapolated_max_discount_erate_funding'] = state_metrics['extrapolated_max_discount_erate_funding_ia'] + state_metrics['extrapolated_max_discount_erate_funding_wan']
state_metrics['extrapolated_max_total_state_funding'] = state_metrics['extrapolated_max_total_state_funding_ia'] + state_metrics['extrapolated_max_total_state_funding_wan']
state_metrics['extrapolated_max_total_erate_funding'] = state_metrics['extrapolated_max_total_erate_funding_ia'] + state_metrics['extrapolated_max_total_erate_funding_wan']
state_metrics['extrapolated_max_total_district_funding'] = 	state_metrics['extrapolated_max_total_district_funding_ia'] + state_metrics['extrapolated_max_total_district_funding_wan']
state_metrics['extrapolated_max_builds'] = 	state_metrics['extrapolated_max_builds_ia'] + state_metrics['extrapolated_max_builds_wan']
state_metrics['extrapolated_max_build_distance'] = 	state_metrics['extrapolated_max_build_distance_ia'] + state_metrics['extrapolated_max_build_distance_wan']
state_metrics['max_total_cost_per_mile'] = 	state_metrics['extrapolated_max_total_cost'] / state_metrics['extrapolated_max_build_distance']
state_metrics['max_miles_per_build'] = 	state_metrics['extrapolated_max_build_distance'] / state_metrics['extrapolated_max_builds']

state_metrics = state_metrics[[	'district_postal_cd', 'extrapolated_min_total_cost', 'extrapolated_min_total_state_funding', 'extrapolated_min_total_erate_funding',
								'extrapolated_min_total_district_funding', 'extrapolated_min_builds', 'extrapolated_min_build_distance', 'min_total_cost_per_mile', 'min_miles_per_build',
								'extrapolated_max_total_cost', 'extrapolated_max_total_state_funding', 'extrapolated_max_total_erate_funding',
								'extrapolated_max_total_district_funding', 'extrapolated_max_builds', 'extrapolated_max_build_distance', 'max_total_cost_per_mile', 'max_miles_per_build',
								'extrapolated_max_total_cost_wan', 'extrapolated_max_total_state_funding_wan', 'extrapolated_max_total_erate_funding_wan',
								'extrapolated_max_total_district_funding_wan', 'extrapolated_max_builds_wan', 'extrapolated_max_build_distance_wan',
								'extrapolated_min_total_cost_wan', 'extrapolated_min_total_state_funding_wan', 'extrapolated_min_total_erate_funding_wan',
								'extrapolated_min_total_district_funding_wan', 'extrapolated_min_builds_wan', 'extrapolated_min_build_distance_wan',
								'extrapolated_total_cost_az_wan', 'extrapolated_total_state_funding_az_wan', 'extrapolated_total_erate_funding_az_wan',
								'extrapolated_total_district_funding_az_wan', 'extrapolated_builds_az_wan', 'extrapolated_build_distance_az_wan',
								'extrapolated_total_cost_az_pop_wan', 'extrapolated_total_state_funding_az_pop_wan', 'extrapolated_total_erate_funding_az_pop_wan',
								'extrapolated_total_district_funding_az_pop_wan', 'extrapolated_builds_az_pop_wan', 'extrapolated_build_distance_az_pop_wan',
								'extrapolated_min_builds_ia', 'extrapolated_max_builds_ia'
								]]

state_metrics.columns = [	'district_postal_cd', 'min_total_cost', 'min_total_state_funding', 'min_total_erate_funding',
							'min_total_district_funding', 'min_builds', 'min_build_distance', 'min_total_cost_per_mile', 'min_miles_per_build',
							'max_total_cost', 'max_total_state_funding', 'max_total_erate_funding',
							'max_total_district_funding', 'max_builds', 'max_build_distance', 'max_total_cost_per_mile', 'max_miles_per_build',
							'max_total_cost_wan', 'max_total_state_funding_wan', 'max_total_erate_funding_wan',
							'max_total_district_funding_wan', 'max_builds_wan', 'max_build_distance_wan',
							'min_total_cost_wan', 'min_total_state_funding_wan', 'min_total_erate_funding_wan',
							'min_total_district_funding_wan', 'min_builds_wan', 'min_build_distance_wan',
							'total_cost_az_wan', 'total_state_funding_az_wan', 'total_erate_funding_az_wan',
							'total_district_funding_az_wan', 'builds_az_wan', 'build_distance_az_wan',
							'total_cost_az_pop_wan', 'total_state_funding_az_pop_wan', 'total_erate_funding_az_pop_wan',
							'total_district_funding_az_pop_wan', 'builds_az_pop_wan', 'build_distance_az_pop_wan',
							'min_builds_ia', 'max_builds_ia'
							]

state_metrics['advice_max_cost_per_mile'] = where(state_metrics['max_total_cost_per_mile']>=100000,
														'high - skew towards minimum',
														'no insight')
state_metrics['advice_ia_builds'] = where(state_metrics['max_builds_ia']<10,
												'low - skew towards minimum',
												'no insight')
state_metrics['advice_ratio_miles_per_build'] = where(state_metrics['max_miles_per_build']/state_metrics['min_miles_per_build']>2,
															'high - skew towards minimum',
															'no insight')
state_metrics['advice_skew'] = where(	logical_or(	(state_metrics['total_cost_az_wan']-state_metrics['min_total_cost_wan'])/(state_metrics['total_cost_az_pop_wan']-state_metrics['min_total_cost_wan'])>3,
													(state_metrics['total_cost_az_pop_wan']-state_metrics['min_total_cost_wan'])/(state_metrics['total_cost_az_wan']-state_metrics['min_total_cost_wan'])>3),
															'high - skew towards minimum',
															'no insight')

state_metrics.to_csv('../../data/processed/state_metrics.csv')
print("File saved")


