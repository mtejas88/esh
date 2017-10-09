#!/bin/bash

echo "$(date)"
. /home/sat/.bash_profile
echo "Starting..."
cd "/home/sat/ficher/Projects/funding_the_gap_2017/src_2017_sc/models/"
python distance_calculator.py &&
python unscalable_campuses.py &&
wait
python build_cost_calculator_apop.py &
python build_cost_calculator_az.py &
python build_cost_calculator_zpop.py &
wait
echo "Campus Costs calculated"
python build_cost_per_mile_wan.py &&
python build_cost_distributor_wan.py &&
python unscalable_districts.py &&
python build_cost_calculator_ia.py &&
python build_cost_distributor_ia.py &&
python aggregator_state.py &&
python aggregator_state_tableau.py &&
python regression.py &&
python tableau_db_insert.py &&
echo "Done!"
