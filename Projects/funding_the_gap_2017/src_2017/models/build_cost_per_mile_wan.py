from pandas import read_csv, merge
from numpy import where, logical_or

import sys
sys.path.insert(0, '../features')

from classes import cost_magnifier

campus_costs_apop = read_csv('../../data/interim/campus_costs_apop.csv')
campus_costs_zpop = read_csv('../../data/interim/campus_costs_zpop.csv')
campus_costs_az = read_csv('../../data/interim/campus_costs_az.csv')
unscalable_campuses = read_csv('../../data/interim/unscalable_campuses.csv')
print("Campuses costs imported")

campus_build_costs = unscalable_campuses.merge(campus_costs_apop, left_on=['campus_id','esh_id'], right_on=['campus_id','esh_id'], how='outer')
campus_build_costs = campus_build_costs.merge(campus_costs_zpop, left_on=['campus_id','esh_id'], right_on=['campus_id','esh_id'], how='outer')
campus_build_costs = campus_build_costs.merge(campus_costs_az, left_on=['campus_id','esh_id'], right_on=['campus_id','esh_id'], how='outer')

campus_build_costs['build_cost_az_pop'] = where(logical_or(campus_build_costs['build_cost_apop']<0,campus_build_costs['build_cost_zpop']<0),
												-1,
												campus_build_costs['build_cost_apop']+campus_build_costs['build_cost_zpop'])
campus_build_costs['build_distance_az_pop'] = campus_build_costs['build_distance_apop']+campus_build_costs['build_distance_zpop']
#campus_build_costs['min_build_cost'] = campus_build_costs[['build_cost_az_pop', 'build_cost_az']].min(axis=1)
#campus_build_costs['max_build_cost'] = campus_build_costs[['build_cost_az_pop', 'build_cost_az']].max(axis=1)
campus_build_costs.to_csv('../../data/interim/campus_build_costs_before_distribution.csv')
print("Campuses costs range calculated")

#aggregate by state
state_cost_per_mile = campus_build_costs.loc[campus_build_costs['distance'] > 0]
state_cost_per_mile = campus_build_costs.loc[campus_build_costs['build_distance_az_pop'] > 0]
state_cost_per_mile = state_cost_per_mile.loc[state_cost_per_mile['build_cost_az'] > 0]
state_cost_per_mile = state_cost_per_mile.loc[state_cost_per_mile['build_cost_az_pop'] > 0]
state_cost_per_mile = state_cost_per_mile.groupby(['district_postal_cd']).sum()
state_cost_per_mile = state_cost_per_mile[['build_cost_az_pop', 'build_cost_az', 'build_distance_az_pop', 'distance']]
state_cost_per_mile['build_cost_az_pop_per_mile'] = state_cost_per_mile['build_cost_az_pop'] / state_cost_per_mile['build_distance_az_pop']
state_cost_per_mile['build_cost_az_per_mile'] = state_cost_per_mile['build_cost_az'] / state_cost_per_mile['distance']
state_cost_per_mile = state_cost_per_mile[['build_cost_az_pop_per_mile', 'build_cost_az_per_mile']]
#state_cost_per_mile['min_build_cost_per_mile'] = state_cost_per_mile[['build_cost_az_pop_per_mile', 'build_cost_az_per_mile']].min(axis=1)
#state_cost_per_mile['max_build_cost_per_mile'] = state_cost_per_mile[['build_cost_az_pop_per_mile', 'build_cost_az_per_mile']].max(axis=1)
#state_cost_per_mile = state_cost_per_mile[['max_build_cost_per_mile', 'min_build_cost_per_mile']]
state_cost_per_mile = state_cost_per_mile.reset_index()
print("Costs per mile calculated")

state_cost_per_mile.to_csv('../../data/interim/state_cost_per_mile.csv')
print("File saved")

