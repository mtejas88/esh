##Determining if indicator of 0 bids has effect on fiber target status.
import sys
sys.modules[__name__].__dict__.clear()

##packages
import matplotlib.pyplot as plt
import pylab
import pandas as pd
import numpy as np
import scipy
import statsmodels.api as sm

## data prep
#import
districts_for_ia_bw_reg = pd.read_csv('data/interim/districts_for_sc_reg.csv')
#clean for cost only for regression
districts_for_ia_bw_reg = districts_for_ia_bw_reg.loc[districts_for_ia_bw_reg['exclude_from_ia_analysis'] == False]
#aggregate 2+,3+
districts_for_ia_bw_reg['frns_2p_bid_ia_indicator']  = np.where(np.logical_or(districts_for_ia_bw_reg['frns_2_bid_ia_indicator'] == True, districts_for_ia_bw_reg['frns_3p_bid_ia_indicator'] == True), True, False)
#add factor for if state procures independently - https://docs.google.com/document/d/1dXYTiRystJK_SfM9pO3ZBrsOYRIUhON-nWs169Oigr8/
state_procures_independently = ['AK', 'AZ', 'CT', 'CO', 'FL', 'ID', 'IL', 'IN', 'KS', 'LA', 'MA', 'MD', 'MT', 'NH', 'NJ', 'NM', 'NV', 'OK', 'TN', 'VA', 'VT']
districts_for_ia_bw_reg['state_procures_independently'] = districts_for_ia_bw_reg['postal_cd'].isin(state_procures_independently)

## modeling prep
locale_dummies = pd.get_dummies(districts_for_ia_bw_reg.locale, prefix='locale')
#.iloc[:, 1:]
districts_for_ia_bw_reg = pd.concat([districts_for_ia_bw_reg, locale_dummies], axis=1)

type_dummies = pd.get_dummies(districts_for_ia_bw_reg.district_type, prefix='type')
#.iloc[:, 1:]
districts_for_ia_bw_reg = pd.concat([districts_for_ia_bw_reg, type_dummies], axis=1)

#add overall ia bandwidth as cost factor
feature_cols_ia_bw = ['frns_0_bid_ia_indicator', 'frns_1_bid_ia_indicator', 'frns_2p_bid_ia_indicator', 'locale_Rural', 'locale_Suburban', 'locale_Town', 'state_procures_independently', 'num_students', 'type_Charter']

X_ia_bw = districts_for_ia_bw_reg[feature_cols_ia_bw ]
y_ia_bw = districts_for_ia_bw_reg.ia_bandwidth_per_student_kbps

data_true_bw = districts_for_ia_bw_reg.loc[districts_for_ia_bw_reg['frns_2p_bid_ia_indicator'] == True]
data_true_bw = data_true_bw.ia_bandwidth_per_student_kbps

data_false_bw = districts_for_ia_bw_reg.loc[districts_for_ia_bw_reg['frns_2p_bid_ia_indicator'] == False]
data_false_bw = data_false_bw.ia_bandwidth_per_student_kbps

data_true_bw_0 = districts_for_ia_bw_reg.loc[districts_for_ia_bw_reg['frns_0_bid_ia_indicator'] == True]
data_true_bw_0 = data_true_bw_0.ia_bandwidth_per_student_kbps

data_false_bw_0 = districts_for_ia_bw_reg.loc[districts_for_ia_bw_reg['frns_0_bid_ia_indicator'] == False]
data_false_bw_0 = data_false_bw_0.ia_bandwidth_per_student_kbps

## statsmodels model
X_ia_bw = sm.add_constant(X_ia_bw)
est_ia_bw = sm.OLS(y_ia_bw, X_ia_bw.astype(float)).fit()
print(est_ia_bw.summary())

## t test
ttest_ia_bw  = scipy.stats.ttest_ind(data_true_bw, data_false_bw, equal_var=False)
print("Fail to reject null hypothesis; districts that receive 2+ bids on one of their internet access services have similar bw/student as districts with only 0, 1 bid internet access services. P-value: {}".format(round(ttest_ia_bw.pvalue,2)))
print("Mean bw/student for districts that receive 2+ bids on one of their internet access services: {}".format(round(np.mean(data_true_bw),2)))
print("Mean bw/student for districts that receive 0, 1 bids on all of their internet access services: {}".format(round(np.mean(data_false_bw),2)))

ttest_ia_bw_0  = scipy.stats.ttest_ind(data_true_bw_0, data_false_bw_0, equal_var=False)
#p-value divided by 2 for a one-tailed test (since we want to see if 0 bids are significantly GREATER THAN non-0 bids
print("Reject null hypothesis; districts that receive 0 bids on one of their internet access services have more bw/student than districts with only 1+ bid internet access services. P-value: {}".format(round(ttest_ia_bw_0.pvalue/2,2)))
print("Mean bw/student for districts that receive 0 bids on one of their internet access services: {}".format(round(np.mean(data_true_bw_0),2)))
print("Mean bw/student for districts that receive 1+ bids on all of their internet access services: {}".format(round(np.mean(data_false_bw_0),2)))
