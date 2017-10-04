##imports and definitions
#packages
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import statsmodels.api as sm
from sklearn.cross_validation import train_test_split
from sklearn.metrics import confusion_matrix, classification_report
from imblearn.under_sampling import RandomUnderSampler

#import environment variables
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

#import data
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 
frns_2016 = pd.read_csv('frns_2016.csv', encoding = "ISO-8859-1")
frns_2017 = pd.read_csv('frns_2017.csv', encoding = "ISO-8859-1")
#low priority -- append 2016/2017 using feature columns, and then filter to those that are in this CSV. this is because everything before "features for inclusion" has already been done to frns_model & would be best to be consistent
#frns_model = pd.read_csv('frns_model.csv', encoding = "ISO-8859-1")

##prep data for modeling
#model using cat 1 data only
frns_2016_model  = frns_2016.loc[frns_2016['category_of_service'] < 2].copy()
frns_2017_model  = frns_2017.loc[frns_2017['category_of_service'] < 2].copy()

#model without special construction apps only
frns_2016_model_model  = frns_2016_model.loc[frns_2016_model['special_construction_indicator'] < 1]
frns_2017  = frns_2017_model.loc[frns_2017_model['special_construction_indicator'] < 1]

#filter to those frns where none of the FRNS have a pending or cancelled status
frns_2016_model  = frns_2016_model.loc[np.logical_or(frns_2016_model['funded_frn']> 0, frns_2016_model['denied_frn'])>0]
frns_2017_model  = frns_2017_model.loc[np.logical_or(frns_2017_model['funded_frn']> 0, frns_2017_model['denied_frn'])>0]

#create denial indicator
frns_2016_model['orig_denied_frn'] = np.where(np.logical_or(frns_2016_model.denied_frn, frns_2016_model.appealed_funded_frn),1,0)
frns_2017_model['orig_denied_frn'] = np.where(np.logical_or(frns_2017_model.denied_frn, frns_2017_model.appealed_funded_frn),1,0)

#features for inclusion
feature_cols = [
'frn_0_bids', 'consultant_indicator', 'locale_Rural', 
'denied_indicator_py', 
#include only variables below this line had straight approval accuracy 64% with r2 .062
#'internet_indicator', 
#'applicant_type_School',
#variables before this line had straight approval accuracy 71% with r2 .056
'service_Voice',
'discount_category'
]

insig_cols = ['applicant_type_Library', 'applicant_type_Consortium', 'applicant_type_Library System', 'copper_indicator', 'wireless_indicator', 'service_Data Transmission and/or Internet Access', 'total_eligible_one_time_costs', 'total_monthly_eligible_recurring_costs', 'total_funding_year_commitment_amount_request', 'line_items', 'num_recipients',  'fulltime_enrollment', 'wan_indicator']

#frns with modeling inputs
frns_2016_model = pd.concat([frns_2016_model[feature_cols], frns_2016_model.orig_denied_frn], axis=1)
frns_2017_model = pd.concat([frns_2017_model[feature_cols], frns_2017_model.orig_denied_frn], axis=1)

#append 2016 and 2017 frns
frns_model = pd.concat([frns_2016_model, frns_2017_model], axis=0)

#split into test and train sets
train, test = train_test_split(frns_model, train_size=0.75, random_state=1)

#create train inputs
X = train[feature_cols]
y = train.orig_denied_frn

#undersample approved frns due to low number of denials
#to-do: see if removing this makes accuracy we want higher
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X,y)
rows = X_res.shape[0]
X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_frn'])

#add constant for regression model
X_res = sm.add_constant(X_res)

##run regression model
#run regression model on train set
logit = sm.Logit(y_res, X_res.astype(float)).fit()

#create test inputs
X_test = test[feature_cols]
y_test = test.orig_denied_frn

#add constant for regression model
X_test = sm.add_constant(X_test)

#run regression model on test set
yhat_test = logit.predict(X_test)

#cat results to different optimizations
yhat_test_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_test ]
yhat_test_approval_optimized = [ 0 if y < 0.75 else 1 for y in yhat_test ]
yhat_test_balanced = [ 0 if y < 0.5 else 1 for y in yhat_test ]

#create confusion matrices
cm_denial_optimized = confusion_matrix(yhat_test_denial_optimized, y_test)
cm_approval_optimized = confusion_matrix(yhat_test_approval_optimized, y_test)
cm_balanced = confusion_matrix(yhat_test_balanced, y_test)

#create classification reports
cr_denial_optimized = classification_report(y_test, yhat_test_denial_optimized, digits=3)
cr_approval_optimized = classification_report(y_test, yhat_test_approval_optimized, digits=3)
cr_balanced = classification_report(y_test, yhat_test_balanced, digits=3)

#accuracy of approvals
false_pos_pct = cm_approval_optimized[1][0]/(cm_approval_optimized[1][0]+cm_approval_optimized[0][0])


##print regression results
#plot histogram of denial probabilities
#plt.hist(yhat_test,100)
#plt.show()

#print reports, denial optimized
print(cm_denial_optimized)
print(cr_denial_optimized)

#print reports, balanced
print(cm_balanced)
print(cr_balanced)

#print summary of model
print(logit.summary())

#print reports, approval optimized
print(cm_approval_optimized)
print(cr_approval_optimized)

## predict funding status (2016) denial optimized
#create 2016 inputs
X_2016 = frns_2016[feature_cols]
X_2016 = sm.add_constant(X_2016)

#run regression model on 2016 set
yhat_2016 = logit.predict(X_2016)

#cat results to optimize denial accuracy
yhat_2016_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_2016 ]
yhat_2016_approval_optimized = [ 0 if y < .75 else 1 for y in yhat_2016 ]
yhat_2016_balanced = [ 0 if y < 0.5 else 1 for y in yhat_2016 ]

#prep predictions to merge results predictions with inputs
rows = yhat_2016.count()
yhat_2016_approval_optimized = pd.DataFrame(data=yhat_2016_approval_optimized, index=range(rows), columns=['yhat'])

#reset index for merge
frns_2016 = frns_2016.reset_index()

#merge results predictions with inputs
summary_2016_approval_optimized = frns_2016.merge(yhat_2016_approval_optimized, left_index=True, right_index=True)

#create indicator for appeals FRNs
summary_2016_approval_optimized['y'] = np.logical_or(summary_2016_approval_optimized.denied_frn, summary_2016_approval_optimized.appealed_funded_frn)

#filter to 50k for summary
summary_2016_50k_approval_optimized  = summary_2016_approval_optimized.loc[summary_2016_approval_optimized['total_funding_year_commitment_amount_request'] < 50000]

#create summary of results lt 50k
#include appeals frns or no
#summarize_2016_50k_approval_optimized = summary_2016_50k_approval_optimized.groupby(['yhat','denied_frn']).agg({'total_frn_funding': 'sum', 'frn': 'count'})
summarize_2016_50k_approval_optimized = summary_2016_50k_approval_optimized.groupby(['yhat','y']).agg({'total_frn_funding': 'sum', 'frn': 'count'})

#calculate percent false positives of approvals to apply to 2017 -- frns
false_pos_pct_approval_optimized_frns = summarize_2016_50k_approval_optimized['frn'][0][1] / (summarize_2016_50k_approval_optimized['frn'][0][1] + summarize_2016_50k_approval_optimized['frn'][0][0])

#calculate percent false positives of approvals to apply to 2017 -- $
false_pos_pct_approval_optimized_dlrs = summarize_2016_50k_approval_optimized['total_frn_funding'][0][1] / (summarize_2016_50k_approval_optimized['total_frn_funding'][0][1] + summarize_2016_50k_approval_optimized['total_frn_funding'][0][0])

#calculate percent false positives of approvals to apply to 2017 -- applications
#aggregate applications by status
summarize_2016_50k_apps_denied = summary_2016_50k_approval_optimized.groupby(['application_number', 'y']).agg({'frn': 'count'})

#create list of applications denied
summarize_2016_50k_apps_denied = summarize_2016_50k_apps_denied.loc[pd.IndexSlice[:,[1]],:]

#aggregate applications by estimated status
summarize_2016_50k_apps_est_denied = summary_2016_50k_approval_optimized.groupby(['application_number', 'yhat']).agg({'frn': 'count'})

#create list of applications we denied
summarize_2016_50k_apps_est_denied = summarize_2016_50k_apps_est_denied.loc[pd.IndexSlice[:,[1]],:]

#aggregate applications 
summarize_2016_50k_apps = summary_2016_50k_approval_optimized.groupby('application_number').agg({'total_frn_funding': 'sum'})

#reset index for merge
summarize_2016_50k_apps = summarize_2016_50k_apps.reset_index()  
summarize_2016_50k_apps_denied = summarize_2016_50k_apps_denied.reset_index()  
summarize_2016_50k_apps_est_denied = summarize_2016_50k_apps_est_denied.reset_index()  

#determine if application has any denial
summarize_2016_50k_apps = pd.merge(summarize_2016_50k_apps, summarize_2016_50k_apps_denied, on = 'application_number', how = 'outer')
summarize_2016_50k_apps = pd.merge(summarize_2016_50k_apps, summarize_2016_50k_apps_est_denied, on = 'application_number', how = 'outer')

#fill in approvals
summarize_2016_50k_apps['y'] = np.where(summarize_2016_50k_apps['y']==True, True, False)
summarize_2016_50k_apps['yhat'] = np.where(summarize_2016_50k_apps['yhat']==1, 1, 0)


#aggregate applications
summarize_2016_50k_approval_optimized_apps = summarize_2016_50k_apps.groupby(['yhat','y']).agg({'application_number': 'count'})

#calculate percent false positives of approvals to apply to 2017 -- applications
false_pos_pct_approval_optimized_apps = summarize_2016_50k_approval_optimized_apps['application_number'][0][1] / (summarize_2016_50k_approval_optimized_apps['application_number'][0][1] + summarize_2016_50k_approval_optimized_apps['application_number'][0][0])

#aggregate applications by estimated status
summarize_2016_50k_apps_est_denied = summary_2016_50k_approval_optimized.groupby(['application_number', 'yhat']).agg({'frn': 'count'})

#create list of applications we denied
summarize_2016_50k_apps_est_denied = summarize_2016_50k_apps_est_denied.loc[pd.IndexSlice[:,[1]],:]

#aggregate applications 
summarize_2016_50k_apps = summary_2016_50k_approval_optimized.groupby('application_number').agg({'total_frn_funding': 'sum'})

#reset index for merge
summarize_2016_50k_apps = summarize_2016_50k_apps.reset_index()  
summarize_2016_50k_apps_est_denied = summarize_2016_50k_apps_est_denied.reset_index()  

#determine if application has any denial
summarize_2016_50k_apps = pd.merge(summarize_2016_50k_apps, summarize_2016_50k_apps_est_denied, on = 'application_number', how = 'outer')

#fill in approvals
summarize_2016_50k_apps['yhat'] = np.where(summarize_2016_50k_apps['yhat']==1, 1, 0)

#aggregate applications
summarize_2016_50k_approval_optimized_apps = summarize_2016_50k_apps.groupby(['yhat']).agg({'application_number': 'count'})

## predict funding status (2017) denial optimized
#create 2017 inputs
X_2017 = frns_2017[feature_cols]
X_2017 = sm.add_constant(X_2017)

#run regression model on 2017 set
yhat_2017 = logit.predict(X_2017)

#cat results to optimize denial accuracy
yhat_2017_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_2017 ]
yhat_2017_approval_optimized = [ 0 if y < .75 else 1 for y in yhat_2017 ]
yhat_2017_balanced = [ 0 if y < 0.5 else 1 for y in yhat_2017 ]

#prep predictions to merge results predictions with inputs
rows = yhat_2017.count()
yhat_2017_approval_optimized = pd.DataFrame(data=yhat_2017_approval_optimized, index=range(rows), columns=['yhat'])

#reset index for merge
frns_2017 = frns_2017.reset_index()

#merge results predictions with inputs
summary_2017_approval_optimized = frns_2017.merge(yhat_2017_approval_optimized, left_index=True, right_index=True)

#filter to 50k for summary
summary_2017_50k_approval_optimized  = summary_2017_approval_optimized.loc[summary_2017_approval_optimized['total_funding_year_commitment_amount_request'] < 50000]

#create summary of results lt 50k
summarize_2017_50k_approval_optimized = summary_2017_50k_approval_optimized.groupby('yhat').agg({'total_frn_funding': 'sum', 'frn': 'count'})

#aggregate applications by estimated status
summarize_2017_50k_apps_est_denied = summary_2017_50k_approval_optimized.groupby(['application_number', 'yhat']).agg({'frn': 'count'})

#create list of applications we denied
summarize_2017_50k_apps_est_denied = summarize_2017_50k_apps_est_denied.loc[pd.IndexSlice[:,[1]],:]

#aggregate applications 
summarize_2017_50k_apps = summary_2017_50k_approval_optimized.groupby('application_number').agg({'total_frn_funding': 'sum'})

#reset index for merge
summarize_2017_50k_apps = summarize_2017_50k_apps.reset_index()  
summarize_2017_50k_apps_est_denied = summarize_2017_50k_apps_est_denied.reset_index()  

#determine if application has any denial
summarize_2017_50k_apps = pd.merge(summarize_2017_50k_apps, summarize_2017_50k_apps_est_denied, on = 'application_number', how = 'outer')

#fill in approvals
summarize_2017_50k_apps['yhat'] = np.where(summarize_2017_50k_apps['yhat']==1, 1, 0)

#aggregate applications
summarize_2017_50k_approval_optimized_apps = summarize_2017_50k_apps.groupby(['yhat']).agg({'application_number': 'count'})

#potential false positives
false_pos_2017_approval_optimized_frns_pot = false_pos_pct *summarize_2017_50k_approval_optimized['frn'][0]
false_pos_2017_approval_optimized_dlrs_pot = false_pos_pct *summarize_2017_50k_approval_optimized['total_frn_funding'][0]
false_pos_2017_approval_optimized_apps_pot = false_pos_pct *summarize_2017_50k_approval_optimized_apps['application_number'][0]

#actual false positives
false_pos_2017_approval_optimized_frns = false_pos_pct_approval_optimized_frns *summarize_2017_50k_approval_optimized['frn'][0]
false_pos_2017_approval_optimized_dlrs = false_pos_pct_approval_optimized_dlrs *summarize_2017_50k_approval_optimized['total_frn_funding'][0]
false_pos_2017_approval_optimized_apps = false_pos_pct_approval_optimized_apps *summarize_2017_50k_approval_optimized_apps['application_number'][0]

##print prediction results
pd.set_option('display.float_format', lambda x: '%.3f' % x)

print(summarize_2016_50k_approval_optimized)
print(summarize_2016_50k_approval_optimized_apps)
print(summarize_2017_50k_approval_optimized)
print(summarize_2017_50k_approval_optimized_apps)
print("\nFalse approvals calcd using accuracy:")
print(false_pos_2017_approval_optimized_dlrs_pot)
print(false_pos_2017_approval_optimized_frns_pot)
print(false_pos_2017_approval_optimized_apps_pot)
print("\nFalse approvals calcd using 2016 actual:")
print(false_pos_2017_approval_optimized_dlrs)
print(false_pos_2017_approval_optimized_frns)
print(false_pos_2017_approval_optimized_apps)