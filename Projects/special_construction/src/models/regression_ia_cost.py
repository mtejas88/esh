##Determining if indicator of 0 bids has effect on fiber target status.
import sys
sys.modules[__name__].__dict__.clear()

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import statsmodels.api as sm

## data prep
#import
districts_for_ia_cost_reg = pd.read_csv('data/interim/reg/districts_for_sc_reg.csv')
#clean for cost only for regression
districts_for_ia_cost_reg = districts_for_ia_cost_reg.loc[districts_for_ia_cost_reg['exclude_from_ia_cost_analysis'] == False]
districts_for_ia_cost_reg = districts_for_ia_cost_reg.loc[districts_for_ia_cost_reg['postal_cd'] != 'AK']
#aggregate 2+,3+
districts_for_ia_cost_reg['frns_2p_bid_ia_indicator']  = np.where(np.logical_or(districts_for_ia_cost_reg['frns_2_bid_ia_indicator'] == True, districts_for_ia_cost_reg['frns_3p_bid_ia_indicator'] == True), True, False)
#add factor for if state procures independently - https://docs.google.com/document/d/1dXYTiRystJK_SfM9pO3ZBrsOYRIUhON-nWs169Oigr8/
state_procures_independently = ['AK', 'AZ', 'CT', 'CO', 'FL', 'ID', 'IL', 'IN', 'KS', 'LA', 'MA', 'MD', 'MT', 'NH', 'NJ', 'NM', 'NV', 'OK', 'TN', 'VA', 'VT']
districts_for_ia_cost_reg['state_procures_independently'] = districts_for_ia_cost_reg['postal_cd'].isin(state_procures_independently)

## modeling prep
locale_dummies = pd.get_dummies(districts_for_ia_cost_reg.locale, prefix='locale')
#.iloc[:, 1:]
districts_for_ia_cost_reg = pd.concat([districts_for_ia_cost_reg, locale_dummies], axis=1)

type_dummies = pd.get_dummies(districts_for_ia_cost_reg.district_type, prefix='type')
#.iloc[:, 1:]
districts_for_ia_cost_reg = pd.concat([districts_for_ia_cost_reg, type_dummies], axis=1)

#add overall ia bandwidth as cost factor
feature_cols_ia_cost = ['frns_0_bid_ia_indicator', 'frns_1_bid_ia_indicator', 'frns_2p_bid_ia_indicator', 'locale_Rural', 'locale_Suburban', 'locale_Town', 'state_procures_independently', 'num_schools', 'type_Charter', 'type_BIE']

X_ia_cost = districts_for_ia_cost_reg[feature_cols_ia_cost ]
y_ia_cost = districts_for_ia_cost_reg.ia_monthly_cost_per_mbps

## statsmodels model
X_ia_cost = sm.add_constant(X_ia_cost)
est_ia_cost = sm.OLS(y_ia_cost, X_ia_cost.astype(float)).fit()
print(est_ia_cost.summary())
