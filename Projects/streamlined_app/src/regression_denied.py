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
import warnings

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

##regression with test/train
train, test = train_test_split(lowcost_applications, train_size=0.75, random_state=1)

X1 = train[feature_cols]
y1 = train.denied_indicator

# regression model
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X1,y1)
rows = X_res.shape[0]

X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

X_res = sm.add_constant(X_res)

est1 = sm.Logit(y_res, X_res.astype(float)).fit()
print(est1.summary())

# predicting
x_test = test[feature_cols]
x_test = sm.add_constant(x_test)

y_test = test.denied_indicator

yhat_test = est1.predict(x_test)
plt.hist(yhat_test,50)
plt.show()

yhat_test = [ 0 if y < 0.35 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))

##how many apps with worst case were denied funding
wor = lowcost_applications.groupby(['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2'])
print(wor.agg({'application_number': lambda x: x.count()}))

## histograms of all variables
hist_cols = ['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2', 'denied_indicator']
lowcost_applications[hist_cols].hist()
pylab.show()
