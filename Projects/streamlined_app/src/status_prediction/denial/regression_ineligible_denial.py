##include appeals frns or no
#this note is throughout and provides a model based on final approval decision. we determined that initial approval decision is what we want to learn about since that's how this model would be used.

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
frns_cats = pd.read_csv('frns_cats.csv')

##prep data for modeling
#create denial indicator
frns_2016['orig_denied_frn'] = np.where(np.logical_or(frns_2016.denied_frn, frns_2016.appealed_funded_frn),1,0)
frns_2017['orig_denied_frn'] = np.where(np.logical_or(frns_2017.denied_frn, frns_2017.appealed_funded_frn),1,0)

#create features for inclusion - ineligible voice services
frns_2016['ineligible_voice'] = np.where(np.logical_and(frns_2016['service_Voice'] == 1, frns_2016['discount_category'] >= 70),1,0)
frns_2017['ineligible_voice'] = np.where(np.logical_and(frns_2017['service_Voice'] == 1, frns_2017['discount_category'] >= 70),1,0)


#features for inclusion
feature_cols = ['wireless_indicator', 'fiber_indicator', 'service_Voice', 'locale_Rural', 'frn_0_bids', 'applicant_type_Consortium', 'internet_indicator']
#feature_cols = ['ineligible_voice', 'locale_Rural']

#features for inclusion
feature_cols = ['wireless_indicator', 'fiber_indicator', 'service_Voice', 'locale_Rural', 'frn_0_bids', 'applicant_type_Consortium', 'internet_indicator']


#these seem to have high likelihood of being included but make accuracy worse
almost_feature = ['applicant_type_Library System', 'discount_category', 'consultant_indicator', 'applicant_type_Library', 'copper_indicator', 'denied_indicator_py', 'total_monthly_eligible_recurring_costs', 'backbone_indicator',  
#almost
'applicant_type_School',  'line_items', 'wan_indicator', 
'service_Data Transmission and/or Internet Access', 'ineligible_voice']

insig_cols = ['orig_denied_frn',  'applicant_type_School District',    
'total_eligible_one_time_costs', 'total_funding_year_commitment_amount_request', 'num_recipients',  'fulltime_enrollment']

#frns with modeling inputs
frns_2016 = pd.concat([frns_2016[feature_cols], frns_2016[almost_feature], frns_2016[insig_cols], frns_2016['frn']], axis=1)
frns_2017 = pd.concat([frns_2017[feature_cols], frns_2017[almost_feature], frns_2017[insig_cols], frns_2017['frn']], axis=1)

#append 2016 and 2017 frns
frns_model = pd.concat([frns_2016, frns_2017], axis=0)

#only include FRNs that have cats 
frns_model = pd.merge(frns_model, frns_cats, how='left', on='frn')

#reset index
frns_model = frns_model.reset_index(drop = True)

#fill NAs
frns_model = frns_model.fillna(value=0)

#split into test and train sets
train, test = train_test_split(frns_model, train_size=0.75, random_state=1)

#create train inputs
X = train[feature_cols]
y = train['category_Ineligible Services']

#undersample approved frns due to low number of denials
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X,y)
rows = X_res.shape[0]
X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['category_Ineligible Services'])
#add constant for regression model
X_res = sm.add_constant(X_res)

##run regression model
#run regression model on train set
logit = sm.Logit(y_res, X_res.astype(float)).fit()

#create test inputs
X_test = test[feature_cols]
y_test = test['category_Ineligible Services']

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

#print reports, approval optimized
print(cm_approval_optimized)
print(cr_approval_optimized)

#print summary of model
print(logit.summary())

#print reports, balanced
print(cm_balanced)
print(cr_balanced)

##save
frns_model.to_csv('frns_model_denied.csv')