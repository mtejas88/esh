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
lowcost_applications = pd.read_csv('data/interim/lowcost_applications_contd.csv')

##regression with test/train, best for .5 threshold (balanced)
lowcost_applications_c1  = lowcost_applications.loc[lowcost_applications['category_1'] == True]

#remove outliers
mean= np.mean(lowcost_applications_c1['total_eligible_one_time_costs'])
std = np.std(lowcost_applications_c1['total_eligible_one_time_costs'])

lowcost_applications_c1 = lowcost_applications_c1.loc[abs(lowcost_applications_c1['total_eligible_one_time_costs'] - mean) < 3 * std]


#define model inputs
train, test = train_test_split(lowcost_applications_c1, train_size=0.75, random_state=1)

feature_cols = ['locale_Rural', 'category_one_discount_rate', 'consultant_indicator', 'denied_indicator_py',  
'applicant_type_Library', 'applicant_type_Library System', 
'backbone_indicator', 'internet_indicator',  
'copper_indicator',    
'total_eligible_one_time_costs', 
'min_contract_expiry_date_delta']

insig_cols = ['mastercontract_indicator', 'prevyear_indicator', '0bids_indicator', '1bids_indicator',
'applicant_type_School',  'applicant_type_Consortium',  'applicant_type_School District',
'special_construction_indicator', 'datatrans_indicator', 'voice_indicator', 'wan_indicator', 'upstream_indicator','isp_indicator', 
'wireless_indicator', 'fiber_indicator',  
'total_monthly_eligible_recurring_costs', 'total_funding_year_commitment_amount_request', 'num_service_types', 'num_spins', 'frns', 'num_recipients', 'line_items', 'fulltime_enrollment',
'max_contract_expiry_date_delta', 'certified_timestamp_delta']

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

yhat_test = [ 0 if y < 0.5 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))


## 2017 data prep
#import
lowcost_applications = pd.read_csv('data/interim/lowcost_applications_2017_contd.csv')

## predict denial optimized with 2017
x = lowcost_applications[feature_cols]
x = sm.add_constant(x)

yhat = est1.predict(x.T.drop_duplicates().T)
plt.hist(yhat,100)
plt.show()

yhat = [ 0 if y < 0.5 else 1 for y in yhat]

print(yhat.count(1))
print(yhat.count(0))

