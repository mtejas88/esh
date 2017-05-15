##Determining if indicator of 0 bids has effect on fiber target status.
import sys
sys.modules[__name__].__dict__.clear()

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import statsmodels.api as sm
from sklearn.linear_model import LinearRegression

## data prep
#import
districts_for_status_reg = pd.read_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/interim/districts_for_sc_reg.csv')
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

## statsmodels model
X_incl_sm = sm.add_constant(X_incl)
est_incl = sm.OLS(y, X_incl_sm.astype(float)).fit()
print(est_incl.summary())
#X_excl_sm= sm.add_constant(X_excl)
#est_excl = sm.OLS(y, X_excl_sm.astype(float)).fit()
#print(est_excl.summary())

## sklearn model
#lm_incl = LinearRegression()
#lm_excl = LinearRegression()
#lm_incl.fit(X_incl, y)
#lm_excl.fit(X_excl, y)
#print(lm_incl.score(X_incl,y))
#print(lm_excl.score(X_excl,y))
#print(lm_incl.coef_)
#print(lm_excl.coef_)

#regression does this about statistical significance, these are not
#how many records is statistical significance here and did we reach it
#usually we look at this -- % of 1 bid, etc and compare the differences

