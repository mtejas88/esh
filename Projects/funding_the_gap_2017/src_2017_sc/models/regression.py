## Code to run my R model from within Python and export the results to csv
import pandas as pd
import pyper as pr

import os
GITHUB = os.environ.get("GITHUB")

#read in state metrics
state_metrics_2017 = pd.read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/state_metrics.csv',index_col=0)

# CREATE A R INSTANCE WITH PYPER
r = pr.R(use_pandas = True)

r.assign("state.metrics.2017", state_metrics_2017)

# Read in R script for predicting, creating final table (R_script.R is within the current 'models' folder)
f = open("R_script.R", 'r')
r_code = f.read()

# execute R code
r(r_code)

initial_results_2017 = pd.DataFrame(r.get("result_export"))

initial_results_2017.to_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/initial_results_2017.csv')