##below not updated
##Diensioning consultant applications
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/high_cost_profiling') 

##packages
import pandas as pd
import numpy as np


## data prep
applications = pd.read_csv('data/raw/applications.csv')
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10
applications['below_median_funding_request'] = np.where(applications['total_funding_year_commitment_amount_request']<9484.8,True,False)
consultant_applications = applications.loc[applications['consultant_indicator'] == True]

##all consultant apps
print(consultant_applications.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension low cost
lc = consultant_applications.groupby('below_median_funding_request')
print(lc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension service category
cat = consultant_applications.groupby('category_of_service')
print(cat.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension service category
cat = consultant_applications.groupby('category_of_service')
print(cat.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension discount rate
dr = consultant_applications.groupby('discount_category')
print(dr.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))
print(consultant_applications['category_one_discount_rate'].agg([np.median]))

##dimension applicant type
sc = consultant_applications.groupby('applicant_type')
print(sc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension special construction
c_sc = consultant_applications.groupby('special_construction_indicator')
print(c_sc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension SPINs
sp = consultant_applications.groupby('num_spins')
print(sp.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension recipients
rec = consultant_applications.groupby('num_recipients')
print(rec.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))
