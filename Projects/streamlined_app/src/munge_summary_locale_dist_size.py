##Aggregating data for export
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np

## summary all
#import model results
list_50k_2017_approval_optimized = pd.read_csv('data/interim/lowcost_50k_applications_c1_2017_approval_optimized.csv')

list_50k_2017_denial_optimized = pd.read_csv('data/interim/lowcost_50k_applications_c1_2017_denial_optimized.csv')

list_25k_2017_approval_optimized = pd.read_csv('data/interim/lowcost_25k_applications_c1_2017_approval_optimized.csv')

list_25k_2017_denial_optimized = pd.read_csv('data/interim/lowcost_25k_applications_c1_2017_denial_optimized.csv')

#create applicant_group
d = {'applicant_type': ['School', 'School District', 'Consortium', 'Library', 'Library System'], 'applicant_type_group': ['Instructional', 'Instructional', 'Instructional', 'Library', 'Library']}
lookup = pd.DataFrame(data=d, index=range(5))

list_50k_2017_approval_optimized = list_50k_2017_approval_optimized.join(lookup.set_index('applicant_type'), on='applicant_type')

list_50k_2017_denial_optimized = list_50k_2017_denial_optimized.join(lookup.set_index('applicant_type'), on='applicant_type')

list_25k_2017_approval_optimized = list_25k_2017_approval_optimized.join(lookup.set_index('applicant_type'), on='applicant_type')

list_25k_2017_denial_optimized = list_25k_2017_denial_optimized.join(lookup.set_index('applicant_type'), on='applicant_type')

#summarize 
approval_50k =  list_50k_2017_approval_optimized.loc[list_50k_2017_approval_optimized['yhat'] == 0].groupby(['urban_rural_status', 'applicant_type_group']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count', 'fulltime_enrollment': 'sum'})
approval_50k = approval_50k.reset_index()
approval_50k['model'] = '50k approval'

denial_50k =  list_50k_2017_denial_optimized.loc[list_50k_2017_denial_optimized['yhat'] == 0].groupby(['urban_rural_status', 'applicant_type_group']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count', 'fulltime_enrollment': 'sum'})
denial_50k = denial_50k.reset_index()
denial_50k['model'] = '50k denial'

approval_25k =  list_25k_2017_approval_optimized.loc[list_25k_2017_approval_optimized['yhat'] == 0].groupby(['urban_rural_status', 'applicant_type_group']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count', 'fulltime_enrollment': 'sum'})
approval_25k = approval_25k.reset_index()
approval_25k['model'] = '25k approval'

denial_25k =  list_25k_2017_denial_optimized.loc[list_50k_2017_denial_optimized['yhat'] == 0].groupby(['urban_rural_status', 'applicant_type_group']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count', 'fulltime_enrollment': 'sum'})
denial_25k = denial_25k.reset_index()
denial_25k['model'] = '25k denial'

#append and export
summ_3 = approval_50k.append([denial_50k, approval_25k, denial_25k], ignore_index=True)

summ_3.to_csv('data/processed/auto_approval_locale_size.csv')


