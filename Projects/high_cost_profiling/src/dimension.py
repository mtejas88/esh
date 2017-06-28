##Diensioning consultant applications
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/high_cost_profiling') 

##packages
import pandas as pd
import numpy as np


## data prep
applications = pd.read_csv('data/raw/applications_cntd.csv')
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10
applications['1_recipient_indicator'] = np.where(applications['num_recipients']==1,True,False)
applications['below_median_funding_request'] = np.where(applications['total_funding_year_commitment_amount_request']<9484.8,True,False)
applications['high_dr'] = np.where(applications['discount_category']>=80,True,False)
applications['applicant_instructional'] = np.where(np.logical_or(np.logical_or(applications['applicant_type']=='School',applications['applicant_type']=='School District'),applications['applicant_type']=='Consortium'),True,False)
consultant_applications = applications.loc[applications['consultant_indicator'] == True]



##all consultant apps
print(consultant_applications.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

all = consultant_applications.groupby(['category_of_service', 'high_dr', 'applicant_instructional', 'special_construction_indicator', '1_recipient_indicator'])
csv = all.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'})
csv.to_csv('data/interim/unions.csv')

##dimension low cost
lc = consultant_applications.groupby('below_median_funding_request')
print(lc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension service category
cat = consultant_applications.groupby('category_of_service')
print(cat.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

applications_cat_1 = applications.loc[applications['category_of_service'] == 1]
app_cat_1 = applications_cat_1.groupby('service_types')
print(app_cat_1.agg({'application_number': lambda x: x.count()/applications_cat_1['application_number'].count()}))

applications_cat_2 = applications.loc[applications['category_of_service'] == 2]
app_cat_2 = applications_cat_2.groupby('service_types')
print(app_cat_2.agg({'application_number': lambda x: x.count()/applications_cat_2['application_number'].count()}))


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

applications_1_recip = applications.loc[applications['1_recipient_indicator'] == True]
app_1_rec = applications_1_recip.groupby('applicant_type')
print(app_1_rec.agg({'application_number': lambda x: x.count()/applications_1_recip['application_number'].count()}))

