from pandas import merge, read_csv, DataFrame
from numpy import where

state_metrics = read_csv('../../data/external/state_metrics.csv')
print("States imported")

districts = read_csv('../../data/interim/districts.csv')
print("Districts imported")

state_extrapolations = read_csv('../../data/interim/state_extrapolations.csv')
print("Extrapolations imported")

campus_build_costs = read_csv('../../data/interim/campus_build_costs.csv')
print("Campus costs imported")

##Identifying Campuses that Need Support
#nation population
nation_population = districts.sum()
nation_population = nation_population[['district_num_schools', 'district_num_campuses']]

#nation builds
nation_builds = state_metrics.sum()
nation_builds = nation_builds[['extrapolated_campuses_wan']]

#builds not fully funded
state_builds_not_funded = campus_build_costs.loc[campus_build_costs['total_district_funding_az_pop_wan'] > 0]
state_builds_not_funded = state_builds_not_funded.groupby(['district_postal_cd', 'district_exclude_from_ia_analysis']).sum()

state_builds_not_funded = state_builds_not_funded[['build_fraction_wan']]
state_builds_not_funded = state_builds_not_funded.reset_index()
state_builds_not_funded = merge(state_extrapolations, state_builds_not_funded, how='outer', on='district_postal_cd')

state_builds_not_funded_clean = state_builds_not_funded.loc[state_builds_not_funded['district_exclude_from_ia_analysis'] == False]
state_builds_not_funded_clean['extrapolated_builds'] = state_builds_not_funded_clean['build_fraction_wan'] * state_builds_not_funded_clean['extrapolation']
state_builds_not_funded_clean = state_builds_not_funded_clean[['district_postal_cd', 'extrapolated_builds']]

state_builds_not_funded_dirty = state_builds_not_funded.loc[state_builds_not_funded['district_exclude_from_ia_analysis'] == True]

nation_builds_not_funded = merge(state_builds_not_funded_clean, state_builds_not_funded_dirty, how='outer', on='district_postal_cd')

nation_states_not_funded = nation_builds_not_funded['district_postal_cd'].unique()
states_not_funded = len(nation_states_not_funded)

nation_builds_not_funded['extrapolated_builds'] = nation_builds_not_funded['extrapolated_builds'] + nation_builds_not_funded['build_fraction_wan']
nation_builds_not_funded = nation_builds_not_funded.sum()
nation_builds_not_funded = nation_builds_not_funded[['extrapolated_builds']]



print("Schools: {0}".format(nation_population['district_num_schools']))
print("Campuses: {0}".format(nation_population['district_num_campuses']))
print("Campuses that need fiber: {0}".format(nation_builds['extrapolated_campuses_wan']))
print("Campuses not fully funded by E-Rate / State Match: {0}".format(nation_builds_not_funded['extrapolated_builds']))
print("States not fully funded by E-Rate / State Match: {0}".format(states_not_funded))
print("Districts not fully funded by E-Rate / State Match: {0}".format(-1))
#this will be districts that need either internet or WAN build
print("Districts that need fiber: {0}".format(-1))
print("Districts not fully funded by E-Rate / State Match: {0}".format(-1))
print("Districts fully funded by E-Rate / State Match: {0}".format(-1))
print("Average district cost for districts not fully funded by E-Rate / State Match: {0}".format(-1))
print("Total cost <80pct DR: {0}".format(-1))
print("Total cost >=80pct DR: {0}".format(-1))
print("Total cost E-Rate <80pct DR: {0}".format(-1))
print("Total cost E-Rate >=80pct DR: {0}".format(-1))
print("Total cost State <80pct DR: {0}".format(-1))
print("Total cost State >=80pct DR: {0}".format(-1))
print("Total cost District <80pct DR: {0}".format(-1))
print("Total cost District 20pct DR: {0}".format(-1))
print("Total cost District 40pct DR: {0}".format(-1))
print("Total cost District 50pct DR: {0}".format(-1))
print("Total cost District 60pct DR: {0}".format(-1))
print("Total cost District 70pct DR: {0}".format(-1))
print("Total cost E-Rate 20pct DR: {0}".format(-1))
print("Total cost E-Rate 40pct DR: {0}".format(-1))
print("Total cost E-Rate 50pct DR: {0}".format(-1))
print("Total cost E-Rate 60pct DR: {0}".format(-1))
print("Total cost E-Rate 70pct DR: {0}".format(-1))
print("Total cost E-Rate 80pct DR: {0}".format(-1))
print("Total cost E-Rate 90pct DR: {0}".format(-1))
print("Urban campuses that need fiber: {0}".format(-1))
print("Suburban campuses that need fiber: {0}".format(-1))
print("Town campuses that need fiber: {0}".format(-1))
print("Rural campuses that need fiber: {0}".format(-1))
print("Total cost District Urban: {0}".format(-1))
print("Total cost District Suburban: {0}".format(-1))
print("Total cost District Town: {0}".format(-1))
print("Total cost District Rural: {0}".format(-1))
