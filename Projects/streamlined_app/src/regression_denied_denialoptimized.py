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
from sklearn.cross_validation import train_test_split
from sklearn.metrics import confusion_matrix, classification_report
import pylab as pl
from imblearn.under_sampling import RandomUnderSampler

## data prep
#import
applications = pd.read_csv('data/raw/applications_2016_contd.csv')

#create indicators
applications['lowcost_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10

lowcost_applications  = applications.loc[applications['frns'] == applications['funded_frns'] + applications['denied_frns']]
lowcost_applications  = lowcost_applications.loc[lowcost_applications['lowcost_indicator'] == True]

lowcost_applications['denied_indicator'] = np.where(lowcost_applications['denied_frns'] > 0, 1, 0)
lowcost_applications['denied_indicator_py'] = np.where(lowcost_applications['denied_frns_15'] > 0, 1, 0)

lowcost_applications['1bids_indicator'] = np.where(lowcost_applications['num_frns_1_bids'] > 0, 1, 0)
lowcost_applications['0bids_indicator'] = np.where(lowcost_applications['num_frns_0_bids'] > 0, 1, 0)
lowcost_applications['prevyear_indicator'] = np.where(lowcost_applications['num_frns_from_previous_year'] > 0, 1, 0)
lowcost_applications['mastercontract_indicator'] = np.where(lowcost_applications['num_frns_state_master_contract'] > 0, 1, 0)
lowcost_applications['no_consultant_indicator'] = np.where(lowcost_applications['consultant_indicator'] == False, 1, 0)

den = lowcost_applications.groupby('denied_indicator')
print(den.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

applicant_type_dummies = pd.get_dummies(lowcost_applications.applicant_type, prefix='applicant_type')
lowcost_applications = pd.concat([lowcost_applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(lowcost_applications.urban_rural_status, prefix='locale')
lowcost_applications = pd.concat([lowcost_applications, locale_dummies], axis=1)

category_dummies = pd.get_dummies(lowcost_applications.category_of_service, prefix='category')
lowcost_applications = pd.concat([lowcost_applications, category_dummies], axis=1)

lowcost_applications['maintenance_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Basic Maintenance'), 1, 0)
lowcost_applications['connections_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Internal Connections'), 1, 0)
lowcost_applications['managedbb_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Managed Internal Broadband Services'), 1, 0)
lowcost_applications['voice_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Voice'), 1, 0)
lowcost_applications['datatrans_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Data Transmission'), 1, 0)
lowcost_applications['fiber_indicator'] = np.where(lowcost_applications['functions'].str.contains('Fiber'), 1, 0)
lowcost_applications['copper_indicator'] = np.where(lowcost_applications['functions'].str.contains('Copper'), 1, 0)
lowcost_applications['wireless_indicator'] = np.where(lowcost_applications['functions'].str.contains('Wireless'), 1, 0)
lowcost_applications['isp_indicator'] = np.where(lowcost_applications['purposes'].str.contains('ISP'), 1, 0)
lowcost_applications['upstream_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Upstream'), 1, 0)
lowcost_applications['internet_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Internet'), 1, 0)
lowcost_applications['wan_indicator'] = np.where(lowcost_applications['purposes'].str.contains('WAN'), 1, 0)
lowcost_applications['backbone_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
lowcost_applications['min_contract_expiry_date'] = np.where(lowcost_applications['min_contract_expiry_date'] == '06/30/3017', '06/30/2017', lowcost_applications['min_contract_expiry_date'])

lowcost_applications['min_contract_expiry_date'] = pd.to_datetime(lowcost_applications['min_contract_expiry_date'])    
lowcost_applications['min_contract_expiry_date_delta'] = (lowcost_applications['min_contract_expiry_date'] - lowcost_applications['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3019', '06/30/2019', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3018', '06/30/2018', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3017', '06/30/2017', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3016', '06/30/2016', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/2917', '06/30/2017', lowcost_applications['max_contract_expiry_date'])

lowcost_applications['max_contract_expiry_date'] = pd.to_datetime(lowcost_applications['max_contract_expiry_date'])    
lowcost_applications['max_contract_expiry_date_delta'] = (lowcost_applications['max_contract_expiry_date'] - lowcost_applications['max_contract_expiry_date'].min())  / np.timedelta64(1,'D')

lowcost_applications['certified_timestamp'] = pd.to_datetime(lowcost_applications['certified_timestamp'])    
lowcost_applications['certified_timestamp_delta'] = (lowcost_applications['certified_timestamp'] - lowcost_applications['certified_timestamp'].min())  / np.timedelta64(1,'D')

lowcost_applications.to_csv('data/interim/lowcost_applications_contd.csv')

##regression with test/train -- c1 only, best for .35 threshold (denial optimized)
lowcost_applications_c1  = lowcost_applications.loc[lowcost_applications['category_1'] == True]

#remove outliers
mean= np.mean(lowcost_applications_c1['total_monthly_eligible_recurring_costs'])
std = np.std(lowcost_applications_c1['total_monthly_eligible_recurring_costs'])

lowcost_applications_c1 = lowcost_applications_c1.loc[abs(lowcost_applications_c1['total_monthly_eligible_recurring_costs'] - mean) < 3 * std]


#define model inputs
train, test = train_test_split(lowcost_applications_c1, train_size=0.75, random_state=1)

feature_cols = ['locale_Rural', 'category_one_discount_rate', 'consultant_indicator', 'denied_indicator_py',  
'applicant_type_School',  
'backbone_indicator',  
'total_monthly_eligible_recurring_costs', 
'copper_indicator']

insig_cols = ['mastercontract_indicator', 'prevyear_indicator', '0bids_indicator', '1bids_indicator',
'applicant_type_School District', 'applicant_type_Consortium',  'applicant_type_Library System','applicant_type_Library',  
'special_construction_indicator', 'datatrans_indicator', 'internet_indicator', 'wan_indicator',  'voice_indicator', 
'wireless_indicator', 'fiber_indicator',
'total_eligible_one_time_costs', 'total_funding_year_commitment_amount_request', 'num_service_types', 'num_spins', 'frns', 'num_recipients', 'line_items', 'fulltime_enrollment',
'max_contract_expiry_date_delta', 'min_contract_expiry_date_delta', 'certified_timestamp_delta']

X1 = train[feature_cols]
y1 = train.denied_indicator

#run regression model on train set
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X1,y1)
rows = X_res.shape[0]

X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

X_res = sm.add_constant(X_res)

est1 = sm.Logit(y_res, X_res.astype(float)).fit()
print(est1.summary())

#predict on test set
x_test = test[feature_cols]
x_test = sm.add_constant(x_test)

y_test = test.denied_indicator

yhat_test = est1.predict(x_test)
plt.hist(yhat_test,100)
plt.show()

yhat_test = [ 0 if y < 0.35 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))

## 2017 data prep
#import
applications = pd.read_csv('data/raw/applications_2017_contd.csv')

#create indicators
applications['lowcost_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10

#lowcost_applications  = applications.loc[applications['frns'] == applications['funded_frns'] + applications['denied_frns']]
lowcost_applications  = lowcost_applications.loc[lowcost_applications['lowcost_indicator'] == True]

lowcost_applications['denied_indicator'] = np.where(lowcost_applications['denied_frns'] > 0, 1, 0)
lowcost_applications['denied_indicator_py'] = np.where(lowcost_applications['denied_frns_16'] > 0, 1, 0)

applicant_type_dummies = pd.get_dummies(lowcost_applications.applicant_type, prefix='applicant_type')
lowcost_applications = pd.concat([lowcost_applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(lowcost_applications.urban_rural_status, prefix='locale')
lowcost_applications = pd.concat([lowcost_applications, locale_dummies], axis=1)

lowcost_applications['copper_indicator'] = np.where(lowcost_applications['functions'].str.contains('Copper'), 1, 0)
lowcost_applications['internet_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Internet'), 1, 0)
lowcost_applications['backbone_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
lowcost_applications['min_contract_expiry_date'] = pd.to_datetime(lowcost_applications['min_contract_expiry_date'])    
lowcost_applications['min_contract_expiry_date_delta'] = (lowcost_applications['min_contract_expiry_date'] - lowcost_applications['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

lowcost_applications.to_csv('data/interim/lowcost_applications_2017_contd.csv')

## predict denial optimized with 2017
x = lowcost_applications[feature_cols]
x = sm.add_constant(x)

yhat = est1.predict(x.T.drop_duplicates().T)
plt.hist(yhat,100)
plt.show()

yhat = [ 0 if y < 0.35 else 1 for y in yhat]

print(yhat.count(1))
print(yhat.count(0))