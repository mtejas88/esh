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

lowcost_applications['denied_indicator'] = np.where(lowcost_applications['denied_frns'] > 0, 1, 0)
lowcost_applications['no_consultant_indicator'] = np.where(lowcost_applications['consultant_indicator'] == False, 1, 0)

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


feature_cols = ['no_consultant_indicator', 'special_construction_indicator', 'applicant_type_School', 'locale_Urban', 'category_2', 'fulltime_enrollment','num_recipients', 'num_service_types', 'category_one_discount_rate']

insig_cols = ['applicant_type_School District','applicant_type_Consortium','applicant_type_Library']

X = lowcost_applications[feature_cols]
y = lowcost_applications.denied_indicator

# regression model
X = sm.add_constant(X)
est = sm.Logit(y, X.astype(float)).fit()
print(est.summary())

## regression linear model and plot -- NOT FINAL
# regression model
X = lowcost_applications.special_construction_indicator
X = sm.add_constant(X)
y = lowcost_applications.denied_indicator
est_ols = sm.OLS(y, X.astype(float)).fit()
est_log = sm.Logit(y, X.astype(float)).fit()

fig, ax = plt.subplots(figsize=(8,6))
ax.plot(X, est_ols.fittedvalues, 'r--.', label="OLS")
ax.plot(X, est_log.fittedvalues, 'b-', label="Logistic")
ax.plot(X, y, 'go', label="Logistic")
plt.show()


##how many apps with worst case were denied funding
wor = lowcost_applications.groupby(['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2'])
print(wor.agg({'application_number': lambda x: x.count()}))

## histograms of all variables
hist_cols = ['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2', 'denied_indicator']
lowcost_applications[hist_cols].hist()
pylab.show()
