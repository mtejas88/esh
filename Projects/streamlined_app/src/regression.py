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
applications_2016 = pd.read_csv('data/raw/applications_2016.csv')
applications_2017 = pd.read_csv('data/raw/applications_2017.csv')

applications_2016['funding_year'] = '2016'
applications_2017['funding_year'] = '2017'

applications_2017['funded_frns'] = ''
applications_2017['denied_frns'] = ''
applications_2017['frns'] = ''
applications_2017['avg_wave_number'] = ''

applications = pd.concat([applications_2017, applications_2016])
applications['lowcost_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)

applications.to_csv('data/interim/applications.csv')

##regression for low cost
# modeling prep
applicant_type_dummies = pd.get_dummies(applications.applicant_type, prefix='applicant_type')
applications = pd.concat([applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(applications.urban_rural_status, prefix='locale')
applications = pd.concat([applications, locale_dummies], axis=1)

category_dummies = pd.get_dummies(applications.category_of_service, prefix='category')
applications = pd.concat([applications, category_dummies], axis=1)

feature_cols = ['consultant_indicator', 'special_construction_indicator', 'num_service_types', 'num_spins', 'num_recipients', 'applicant_type_Consortium', 'applicant_type_Library', 'applicant_type_Library System', 'applicant_type_School', 'locale_Rural', 'category_1', 'fulltime_enrollment', 'category_one_discount_rate']

X = applications[feature_cols]
y = applications.lowcost_indicator

# regression model
X = sm.add_constant(X)
est = sm.OLS(y, X.astype(float)).fit()
print(est.summary())