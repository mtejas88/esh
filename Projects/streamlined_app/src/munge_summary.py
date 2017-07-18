##Aggregating data for export
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np

## data prep
#import
summ_110k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_110k_applications_c1_2017_approval_optimized.csv')
summ_110k_2017_approval_optimized ['year'] = 2017
summ_110k_2017_approval_optimized ['model'] = '110k approval'
summ_50k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2017_approval_optimized.csv')
summ_50k_2017_approval_optimized ['year'] = 2017
summ_50k_2017_approval_optimized ['model'] = '50k approval'
summ_25k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2017_approval_optimized.csv')
summ_25k_2017_approval_optimized ['year'] = 2017
summ_25k_2017_approval_optimized ['model'] = '25k approval'
summ_25k_2017_denial_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2017_denial_optimized.csv')
summ_25k_2017_denial_optimized ['year'] = 2017
summ_25k_2017_denial_optimized ['model'] = '25k denial'

summ_110k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_110k_applications_c1_2016_approval_optimized.csv')
summ_110k_2016_approval_optimized ['year'] = 2016
summ_110k_2016_approval_optimized ['model'] = '110k approval'
summ_50k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2016_approval_optimized.csv')
summ_50k_2016_approval_optimized ['year'] = 2016
summ_50k_2016_approval_optimized ['model'] = '50k approval'
summ_25k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2016_approval_optimized.csv')
summ_25k_2016_approval_optimized ['year'] = 2016
summ_25k_2016_approval_optimized ['model'] = '25k approval'
summ_25k_2016_denial_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2016_denial_optimized.csv')
summ_25k_2016_denial_optimized ['year'] = 2016
summ_25k_2016_denial_optimized ['model'] = '25k denial'

summ_2016 = pd.read_csv('data/raw/c1_summary_2016.csv')
summ_2017 = pd.read_csv('data/raw/c1_summary_2017.csv')

#append
summ = summ_110k_2017_approval_optimized.append([summ_50k_2017_approval_optimized, summ_25k_2017_approval_optimized, summ_25k_2017_denial_optimized, summ_110k_2016_approval_optimized, summ_50k_2016_approval_optimized, summ_25k_2016_approval_optimized, summ_25k_2016_denial_optimized, summ_2016, summ_2017], ignore_index=True) 

#export
summ.to_csv('data/processed/results_summary.csv')
