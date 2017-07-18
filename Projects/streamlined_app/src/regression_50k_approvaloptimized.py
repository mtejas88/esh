##Determining significant factors for denial
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
import csv

## data prep
#import
lowcost_50k_applications = pd.read_csv('data/interim/lowcost_50k_applications.csv')

lowcost_50k_applications_c1  = lowcost_50k_applications.loc[lowcost_50k_applications['category_1'] == True]

feature_cols = ['locale_Rural', 'category_one_discount_rate', 'consultant_indicator', 'denied_indicator_py',  
'applicant_type_Library', 'applicant_type_Library System',   
'backbone_indicator', 
'copper_indicator',
'total_monthly_eligible_recurring_costs']

insig_cols = ['mastercontract_indicator', 'prevyear_indicator', '1bids_indicator','0bids_indicator', 
'applicant_type_School District','applicant_type_School','applicant_type_Consortium',  
'datatrans_indicator', 'voice_indicator', 'wan_indicator', 'internet_indicator','upstream_indicator','isp_indicator',   'special_construction_indicator', 
'wireless_indicator', 'fiber_indicator',      
'total_eligible_one_time_costs', 'total_funding_year_commitment_amount_request', 'num_service_types', 'num_spins', 'frns', 'num_recipients', 'line_items', 'fulltime_enrollment',
'max_contract_expiry_date_delta', 
'min_contract_expiry_date_delta', 'certified_timestamp_delta']


##regression with test/train, approval optimized

#define model inputs
train, test = train_test_split(lowcost_50k_applications_c1, train_size=0.75, random_state=1)

X1 = train[feature_cols]
y1 = train.denied_indicator

#run regression model on train set
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X1,y1)
rows = X_res.shape[0]

X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

X_res = sm.add_constant(X_res)

est_50k_app = sm.Logit(y_res, X_res.astype(float)).fit()
print(est_50k_app.summary())

#predict on test set
x_test = test[feature_cols]
x_test = sm.add_constant(x_test)

y_test = test.denied_indicator

yhat_test = est_50k_app.predict(x_test)
plt.hist(yhat_test,100)
plt.show()

yhat_test = [ 0 if y < 0.75 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))

## predict denial optimized with 2016
x0  = lowcost_50k_applications_c1
x = x0[feature_cols]
x = sm.add_constant(x)

yhat = est_50k_app.predict(x.T.drop_duplicates().T)
#plt.hist(yhat,100)
#plt.show()

yhat = [ 0 if y < 0.75 else 1 for y in yhat]

rows = yhat.count(1)+yhat.count(0)
yhat = pd.DataFrame(data=yhat, index=range(rows), columns=['yhat'])

x0 = x0.reset_index()
x0 = x0.merge(yhat, left_index=True, right_index=True)

x0.to_csv('data/interim/lowcost_50k_applications_c1_2016_approval_optimized.csv')

x0_summ = x1.groupby('yhat').agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})

x0_summ.to_csv('data/interim/summ_lowcost_50k_applications_c1_2016_approval_optimized.csv')


## 2017 data prep
#import
lowcost_50k_applications_2017 = pd.read_csv('data/interim/lowcost_50k_applications_2017.csv')


## predict denial optimized with 2017
x1  = lowcost_50k_applications_2017.loc[lowcost_50k_applications_2017['category_1'] == True]
x = x1[feature_cols]
x = sm.add_constant(x)

yhat = est_50k_app.predict(x.T.drop_duplicates().T)
#plt.hist(yhat,100)
#plt.show()

yhat = [ 0 if y < 0.75 else 1 for y in yhat]

rows = yhat.count(1)+yhat.count(0)
yhat = pd.DataFrame(data=yhat, index=range(rows), columns=['yhat'])

x1 = x1.reset_index()
x1 = x1.merge(yhat, left_index=True, right_index=True)

x1.to_csv('data/interim/lowcost_50k_applications_c1_2017_approval_optimized.csv')

x1_summ = x1.groupby('yhat').agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})

x1_summ.to_csv('data/interim/summ_lowcost_50k_applications_c1_2017_approval_optimized.csv')
