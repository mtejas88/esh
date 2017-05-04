
# coding: utf-8

# In[5]:

##Determining if indicator of 0 bids has effect on fiber target status.

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import statsmodels.api as sm
from sklearn.linear_model import LinearRegression

districts_for_status_reg = pd.read_csv('../../data/interim/reg/districts_for_sc_reg.csv',index_col=0)
#target, not target only for regression
districts_for_status_reg =  districts_for_status_reg.loc[districts_for_status_reg['fiber_target_status'].isin(['Target', 'Not Target'])]

#aggregate 2+,3+
districts_for_status_reg['frns_2p_bid_indicator']  = np.where(np.logical_or(districts_for_status_reg['frns_2_bid_indicator'] == True, districts_for_status_reg['frns_3p_bid_indicator'] == True), True, False)
#add factor for if state procures independently - https://docs.google.com/document/d/1dXYTiRystJK_SfM9pO3ZBrsOYRIUhON-nWs169Oigr8/
state_procures_independently = ['AK', 'AZ', 'CT', 'CO', 'FL', 'ID', 'IL', 'IN', 'KS', 'LA', 'MA', 'MD', 'MT', 'NH', 'NJ', 'NM', 'NV', 'OK', 'TN', 'VA', 'VT']
districts_for_status_reg['state_procures_independently'] = districts_for_status_reg['postal_cd'].isin(state_procures_independently)

## modeling prep
status_dummies = pd.get_dummies(districts_for_status_reg.fiber_target_status, prefix='status').iloc[:, 1:]
districts_for_status_reg  = pd.concat([districts_for_status_reg, status_dummies], axis=1)

locale_dummies = pd.get_dummies(districts_for_status_reg.locale, prefix='locale')
#.iloc[:, 1:]
districts_for_status_reg = pd.concat([districts_for_status_reg, locale_dummies], axis=1)

type_dummies = pd.get_dummies(districts_for_status_reg.district_type, prefix='type')
#.iloc[:, 1:]
districts_for_status_reg = pd.concat([districts_for_status_reg, type_dummies], axis=1)


feature_cols_incl_bids = ['frns_0_bid_indicator', 'frns_1_bid_indicator', 'frns_2p_bid_indicator', 'locale_Rural', 'locale_Suburban', 'locale_Town', 'state_procures_independently', 'num_schools', 'type_Charter', 'type_BIE']

feature_cols_excl_bids = ['locale_Rural', 'locale_Suburban', 'locale_Town', 'state_procures_independently', 'num_schools', 'type_Charter', 'type_BIE']

X_incl = districts_for_status_reg[feature_cols_incl_bids]
X_excl = districts_for_status_reg[feature_cols_excl_bids]
y = districts_for_status_reg.status_Target

## statsmodels model (Justine)
X_incl_sm = sm.add_constant(X_incl)
est_incl = sm.OLS(y, X_incl_sm.astype(float)).fit()
print(est_incl.summary())

## statsmodels logistic regression model - had problems
# est_incl_log = sm.Logit(y, X_incl_sm.astype(float)).fit()
# print(est_incl_log.summary())

from sklearn.linear_model import LogisticRegression
logreg = LogisticRegression()
model=logreg.fit(X_incl_sm.astype(float),y)


#getting p-values - have to use overkill method unfortunately
from scipy import stats
params = model.coef_
newX=X_incl_sm.astype(float)
predictions = model.predict(newX)
MSE = float((sum((y-predictions)**2)))/(len(newX)-len(newX.columns))
var_b = MSE*(np.linalg.inv(np.dot(newX.T,newX)).diagonal())
sd_b = np.sqrt(var_b)
ts_b = params/ sd_b
p_values =[2*(1-stats.t.cdf(np.abs(i),(len(newX)-1))) for i in ts_b]
p_values = np.round(p_values,3)

results=pd.concat([pd.DataFrame(X_incl_sm.columns),pd.DataFrame(np.transpose(model.coef_)),pd.DataFrame(np.transpose(np.exp(model.coef_))),pd.DataFrame(np.transpose(p_values))],axis=1)
results.columns=['variable','coefficient','odds_ratio_factor','p_value']
print results
#overall we get the same conclusions about the bids and their effect on fiber target status

#will run only if using ipython notebook
import sys
import os
sys.path.append(os.path.abspath('/Users/sierra/Documents/ESH/ficher/General_Resources/common_functions'))
import __main__ as main
import ipynb_convert 
ipynb_convert.executeConvertNotebook('regression.ipynb','regression_qa.py',main)

