##traditional logistic or with stochastic gradient descent
#this note is throughout and provides a more balanced model with stochastic gradient descent. this is not a good option for optimizing approvals.

##include appeals frns or no
#this note is throughout and provides a model based on final approval decision. we determined that initial approval decision is what we want to learn about since that's how this model would be used.

##imports and definitions
#packages
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import statsmodels.api as sm
from sklearn.linear_model import SGDClassifier
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
applications_2016 = pd.read_csv('applications_2016.csv')
applications_2017 = pd.read_csv('applications_2017.csv')

##prep data for modeling
#model using cat 1 data only
applications_2016  = applications_2016.loc[applications_2016['category_of_service'] < 2]
applications_2017  = applications_2017.loc[applications_2017['category_of_service'] < 2]

#model without special construction apps only
applications_2016  = applications_2016.loc[applications_2016['special_construction_indicator'] < 1]
applications_2017  = applications_2017.loc[applications_2017['special_construction_indicator'] < 1]

#filter to those applications where none of the FRNS have a pending or cancelled status
applications_2016_model  = applications_2016.loc[applications_2016['frns'] == applications_2016['funded_frns'] + applications_2016['denied_frns']]
applications_2017_model  = applications_2017.loc[applications_2017['frns'] == applications_2017['funded_frns'] + applications_2017['denied_frns']]

#features for inclusion
feature_cols = ['locale_Rural', 'discount_category', 'consultant_indicator', 'denied_indicator_py', 'applicant_type_Library', 'applicant_type_Library System', 
#these seem to have low likelihood of being included but make accuracy better
'backbone_indicator', 'copper_indicator', 'total_monthly_eligible_recurring_costs']

#these seem to have high likelihood of being included but make accuracy worse
almost_feature = ['0bids_indicator', 'applicant_type_School',  'line_items',
'datatrans_indicator', 'voice_indicator', 'wireless_indicator']

#features for exclusion
insig_cols = ['mastercontract_indicator', 'prevyear_indicator', '1bids_indicator', 'applicant_type_Consortium', 'applicant_type_School District',  
'internet_indicator',  
'fiber_indicator', 'wan_indicator',  
'total_eligible_one_time_costs', 'total_funding_year_commitment_amount_request', 'num_service_types', 'num_spins', 'frns', 'num_recipients',  'fulltime_enrollment','max_contract_expiry_date_delta', 
'min_contract_expiry_date_delta', 'certified_timestamp_delta']

#applications with modeling inputs
applications_2016_model = pd.concat([applications_2016_model[feature_cols], applications_2016_model['denied_indicator'], applications_2016_model['appealed_funded_indicator']], axis=1)
applications_2017_model = pd.concat([applications_2017_model[feature_cols], applications_2017_model['denied_indicator'], applications_2017_model['appealed_funded_indicator']], axis=1)

#create year
#applications_2016_model['2017_funding'] = 1
#applications_2017_model['2017_funding'] = 0

#include funding year in regression
#feature_cols.append('2017_funding')

#append 2016 and 2017 applications
applications_model = pd.concat([applications_2016_model, applications_2017_model], axis=0)

#remove cost outliers for model since cost is a feature for inclusion
#mean= np.mean(applications_model['total_monthly_eligible_recurring_costs'])
#std = np.std(applications_model['total_monthly_eligible_recurring_costs'])
#applications_model = applications_model.loc[abs(applications_model['total_monthly_eligible_recurring_costs'] - mean) < 3 * std]

#split into test and train sets
train, test = train_test_split(applications_model, train_size=.75, random_state=1)

#create train inputs
X = train[feature_cols]
#include appeals frns or no
#y = train.denied_indicator
y = np.logical_or(train.denied_indicator, train.appealed_funded_indicator)

#undersample approved applications due to low number of denials
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X,y)
#traditional logistic or with stochastic gradient descent
rows = X_res.shape[0]
X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

#add constant for regression model
X_res = sm.add_constant(X_res)

##run regression model
#run regression model on train set
#traditional logistic or with stochastic gradient descent
logit = sm.Logit(y_res, X_res.astype(float)).fit()
#logit = SGDClassifier(loss="log").fit(X_res.astype(float), y_res)

#create test inputs
X_test = test[feature_cols]
#include appeals frns or no
#y_test = test.denied_indicator
y_test = np.logical_or(test.denied_indicator, test.appealed_funded_indicator)

#add constant for regression model
X_test = sm.add_constant(X_test)

#run regression model on test set
yhat_test = logit.predict(X_test)

#cat results to different optimizations
yhat_test_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_test ]
yhat_test_approval_optimized = [ 0 if y < .75 else 1 for y in yhat_test ]
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

#traditional logistic or with stochastic gradient descent
#print summary of model
print(logit.summary())
#print(logit.coef_)
#print(logit.coef_)

#print reports, approval optimized
print(cm_approval_optimized)
print(cr_approval_optimized)

## predict funding status (2016)
#create 2016 inputs
X_2016 = applications_2016[feature_cols]
X_2016 = sm.add_constant(X_2016)

#run regression model on 2016 set
yhat_2016 = logit.predict(X_2016)

#cat results to different optimizations
yhat_2016_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_2016 ]
yhat_2016_approval_optimized = [ 0 if y < .75 else 1 for y in yhat_2016 ]
yhat_2016_balanced = [ 0 if y < 0.5 else 1 for y in yhat_2016 ]

#prep predictions to merge results predictions with inputs
#traditional logistic or with stochastic gradient descent
rows = yhat_2016.count()
#rows = len(yhat_2016)
yhat_2016_approval_optimized = pd.DataFrame(data=yhat_2016_approval_optimized, index=range(rows), columns=['yhat'])

#reset index for merge
applications_2016 = applications_2016.reset_index()

#merge results predictions with inputs
summary_2016_approval_optimized = applications_2016.merge(yhat_2016_approval_optimized, left_index=True, right_index=True)

#create indicator for appeals FRNs
summary_2016_approval_optimized['y'] = np.logical_or(summary_2016_approval_optimized.denied_indicator, summary_2016_approval_optimized.appealed_funded_indicator)

#filter to 50k for summary
summary_2016_50k_approval_optimized  = summary_2016_approval_optimized.loc[summary_2016_approval_optimized['total_funding_year_commitment_amount_request'] < 50000]

#create summary of results lt 50k
#include appeals frns or no
#summarize_2016_50k_approval_optimized = summary_2016_50k_approval_optimized.groupby(['yhat','denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
summarize_2016_50k_approval_optimized = summary_2016_50k_approval_optimized.groupby(['yhat','y']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})

#calculate percent false positives of approvals to apply to 2017
false_pos_pct_approval_optimized_apps = summarize_2016_50k_approval_optimized['application_number'][0][1] / (summarize_2016_50k_approval_optimized['application_number'][0][1] + summarize_2016_50k_approval_optimized['application_number'][0][0])
false_pos_pct_approval_optimized_dlrs = summarize_2016_50k_approval_optimized['total_funding_year_commitment_amount_request'][0][1] / (summarize_2016_50k_approval_optimized['total_funding_year_commitment_amount_request'][0][1] + summarize_2016_50k_approval_optimized['total_funding_year_commitment_amount_request'][0][0])

## predict funding status (2017)
#create 2017 inputs
X_2017 = applications_2017[feature_cols]
X_2017 = sm.add_constant(X_2017)

#run regression model on 2017 set
yhat_2017 = logit.predict(X_2017)

#cat results to different optimizations
yhat_2017_denial_optimized = [ 0 if y < 0.3 else 1 for y in yhat_2017 ]
yhat_2017_approval_optimized = [ 0 if y < .75 else 1 for y in yhat_2017 ]
yhat_2017_balanced = [ 0 if y < 0.5 else 1 for y in yhat_2017 ]

#prep predictions to merge results predictions with inputs
#traditional logistic or with stochastic gradient descent
rows = yhat_2017.count()
#rows = len(yhat_2017)
yhat_2017_approval_optimized = pd.DataFrame(data=yhat_2017_approval_optimized, index=range(rows), columns=['yhat'])

#reset index for merge
applications_2017 = applications_2017.reset_index()

#merge results predictions with inputs
summary_2017_approval_optimized = applications_2017.merge(yhat_2017_approval_optimized, left_index=True, right_index=True)

#filter to 50k for summary
summary_2017_50k_approval_optimized  = summary_2017_approval_optimized.loc[summary_2017_approval_optimized['total_funding_year_commitment_amount_request'] < 50000]

#create summary of results lt 50k
summarize_2017_50k_approval_optimized = summary_2017_50k_approval_optimized.groupby('yhat').agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})

#potential false positives
false_pos_2017_approval_optimized_apps_pot = false_pos_pct*summarize_2017_50k_approval_optimized['application_number'][0]
false_pos_2017_approval_optimized_dlrs_pot = false_pos_pct*summarize_2017_50k_approval_optimized['total_funding_year_commitment_amount_request'][0]

#actual false positives
false_pos_2017_approval_optimized_apps = false_pos_pct_approval_optimized_apps *summarize_2017_50k_approval_optimized['application_number'][0]
false_pos_2017_approval_optimized_dlrs = false_pos_pct_approval_optimized_dlrs *summarize_2017_50k_approval_optimized['total_funding_year_commitment_amount_request'][0]

##print prediction results
print(summarize_2016_50k_approval_optimized)
print(summarize_2017_50k_approval_optimized)
print("\nFalse approvals calcd using accuracy:")
print(false_pos_2017_approval_optimized_dlrs_pot)
print(false_pos_2017_approval_optimized_apps_pot)
print("\nFalse approvals calcd using 2016 actual:")
print(false_pos_2017_approval_optimized_dlrs)
print(false_pos_2017_approval_optimized_apps)

