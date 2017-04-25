##Determining if indicator of 0 bids has effect on fiber target status.
import sys
sys.modules[__name__].__dict__.clear()

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import statsmodels.formula.api as smf
from sklearn.linear_model import LogisticRegression

## data prep
#import
districts_for_sc_reg = pd.read_csv('data/interim/reg/districts_for_sc_reg.csv')
#target, not target only for regression
districts_for_sc_reg =  districts_for_sc_reg.loc[districts_for_sc_reg['fiber_target_status'].isin(['Target', 'Not Target'])]
#aggregate 2+,3+
districts_for_sc_reg['frns_2p_bid_indicator']  = np.where(np.logical_or(districts_for_sc_reg['frns_2_bid_indicator'] == True, districts_for_sc_reg['frns_3p_bid_indicator'] == True), True, False)
#add factor for if state procures independently - https://docs.google.com/document/d/1dXYTiRystJK_SfM9pO3ZBrsOYRIUhON-nWs169Oigr8/
state_procures_independently = ['AK', 'AZ', 'CT', 'CO', 'FL', 'ID', 'IL', 'IN', 'KS', 'LA', 'MA', 'MD', 'MT', 'NH', 'NJ', 'NM', 'NV', 'OK', 'TN', 'VA', 'VT']
districts_for_sc_reg['state_procures_independently'] = districts_for_sc_reg['postal_cd'].isin(state_procures_independently)

## model prep
lm_incl = LogisticRegression()
lm_excl = LogisticRegression()

status_dummies = pd.get_dummies(districts_for_sc_reg.fiber_target_status, prefix='status').iloc[:, 1:]
districts_for_sc_reg  = pd.concat([districts_for_sc_reg, status_dummies], axis=1)

locale_dummies = pd.get_dummies(districts_for_sc_reg.locale, prefix='locale').iloc[:, 1:]
districts_for_sc_reg = pd.concat([districts_for_sc_reg, locale_dummies], axis=1)

feature_cols_incl_bids = ['frns_0_bid_indicator', 'frns_1_bid_indicator', 'frns_2p_bid_indicator', 'locale_Town', 'locale_Suburban', 'locale_Urban', 'state_procures_independently']

feature_cols_excl_bids = ['locale_Town', 'locale_Suburban', 'locale_Urban', 'state_procures_independently']

X_incl = districts_for_sc_reg[feature_cols_incl_bids]
X_excl = districts_for_sc_reg[feature_cols_excl_bids]
y = districts_for_sc_reg.status_Target

## model
lm_incl.fit(X_incl, y)
lm_excl.fit(X_excl, y)
print(lm_incl.score(X_incl,y))
print(lm_excl.score(X_excl,y))

#regression does this about statistical significance, these are not
#how many records is statistical significance here and did we reach it
#usually we look at this -- % of 1 bid, etc and compare the differences