##Determining significant factors for cost and plotting cost diff for consultant
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import scipy
import statsmodels.api as sm

## data prep
#import
applications = pd.read_csv('data/interim/applications.csv')
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10
lowcost_applications  = applications.loc[applications['frns'] == applications['funded_frns'] + applications['denied_frns']]
lowcost_applications  = lowcost_applications.loc[lowcost_applications['lowcost_indicator'] == True]

lowcost_applications['denied_indicator'] = np.where(lowcost_applications['denied_frns'] > 0, True, False)
lowcost_applications['no_consultant_indicator'] = np.where(lowcost_applications['consultant_indicator'] == False, True, False)

lowcost_applications['services_2p_indicator'] = np.where(lowcost_applications['num_service_types'] == 1, False, True)

den = lowcost_applications.groupby('denied_indicator')
print(den.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))


##regression for low cost
# modeling prep
applicant_type_dummies = pd.get_dummies(lowcost_applications.applicant_type, prefix='applicant_type')
lowcost_applications = pd.concat([lowcost_applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(lowcost_applications.urban_rural_status, prefix='locale')
lowcost_applications = pd.concat([lowcost_applications, locale_dummies], axis=1)

category_dummies = pd.get_dummies(lowcost_applications.category_of_service, prefix='category')
lowcost_applications = pd.concat([lowcost_applications, category_dummies], axis=1)


feature_cols = ['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2']

insig_cols = ['num_recipients', 'applicant_type_Consortium', 'applicant_type_Library', 'applicant_type_School District', 'category_one_discount_rate', 'fulltime_enrollment']

X = lowcost_applications[feature_cols]
y = lowcost_applications.denied_indicator

# regression model
X = sm.add_constant(X)
est = sm.OLS(y, X.astype(float)).fit()
print(est.summary())

##how many apps with worst case were denied funding
wor = lowcost_applications.groupby(['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2'])
print(wor.agg({'application_number': lambda x: x.count()}))