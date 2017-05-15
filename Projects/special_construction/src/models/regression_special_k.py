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
import seaborn

## data prep
#import
districts_for_speck_reg = pd.read_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/interim/districts_for_sc_reg.csv')

#clean only
districts_for_speck_reg = districts_for_speck_reg.loc[districts_for_speck_reg['exclude_from_ia_cost_analysis'] == False]
districts_for_speck_reg = districts_for_speck_reg.loc[districts_for_speck_reg['postal_cd'] != 'AK']
districts_for_speck_reg = districts_for_speck_reg.loc[districts_for_speck_reg['exclude_from_ia_analysis'] == False]

#aggregate 2+,3+
districts_for_speck_reg['frns_2p_bid_ia_indicator']  = np.where(np.logical_or(districts_for_speck_reg['frns_2_bid_ia_indicator'] == True, districts_for_speck_reg['frns_3p_bid_ia_indicator'] == True), True, False)

#add factor for if state procures independently - https://docs.google.com/document/d/1dXYTiRystJK_SfM9pO3ZBrsOYRIUhON-nWs169Oigr8/

state_procures_independently = ['AK', 'AZ', 'CT', 'CO', 'FL', 'ID', 'IL', 'IN', 'KS', 'LA', 'MA', 'MD', 'MT', 'NH', 'NJ', 'NM', 'NV', 'OK', 'TN', 'VA', 'VT']
districts_for_speck_reg['state_procures_independently'] = districts_for_speck_reg['postal_cd'].isin(state_procures_independently)

#import speck applicants
speck = pd.read_csv('C:/Users/Justine/Documents/GitHub/ficher/Projects/special_construction/data/raw/fiber_applications_with_results.csv')
speck_districts = speck['district_esh_id'].unique()

#create speck variable applicants
districts_for_speck_reg['special_construction_applicant'] = districts_for_speck_reg['esh_id'].isin(speck_districts)



## modeling prep
locale_dummies = pd.get_dummies(districts_for_speck_reg.locale, prefix='locale')
districts_for_speck_reg = pd.concat([districts_for_speck_reg, locale_dummies], axis=1)

type_dummies = pd.get_dummies(districts_for_speck_reg.district_type, prefix='type')
districts_for_speck_reg = pd.concat([districts_for_speck_reg, type_dummies], axis=1)

fiber_target_status_dummies = pd.get_dummies(districts_for_speck_reg.fiber_target_status, prefix='fiber_target')
districts_for_speck_reg = pd.concat([districts_for_speck_reg, fiber_target_status_dummies], axis=1)

#add overall ia bandwidth as cost factor
feature_cols_speck = ['frns_0_bid_ia_indicator', 'frns_1_bid_ia_indicator', 'frns_2p_bid_ia_indicator', 'locale_Rural', 'locale_Suburban', 'locale_Town', 'state_procures_independently', 'num_schools', 'type_Charter',  'ia_monthly_cost_per_mbps', 'ia_bandwidth_per_student_kbps', 'fiber_target_Target','fiber_target_Not Target','fiber_target_Potential Target']

X_speck = districts_for_speck_reg[feature_cols_speck]
y_speck= districts_for_speck_reg.special_construction_applicant

#data_true = districts_for_speck_reg.loc[districts_for_speck_reg['frns_0_bid_ia_indicator'] == True]
#data_true = data_true.ia_monthly_cost_per_mbps

#data_false = districts_for_speck_reg.loc[districts_for_speck_reg['frns_0_bid_ia_indicator'] == False]
#data_false = data_false.ia_monthly_cost_per_mbps

## statsmodels model
X_speck= sm.add_constant(X_speck)
est_speck = sm.OLS(y_speck, X_speck.astype(float)).fit()
print(est_speck.summary())

## t test
ttest_ia_cost  = scipy.stats.ttest_ind(data_true, data_false, equal_var=False)
#p-value divided by 2 for a one-tailed test (since we want to see if 0 bids are significantly GREATER THAN non-0 bids
pvalue = round(ttest_ia_cost.pvalue/2,2)
mu_true = round(np.mean(data_true),2)
mu_false = round(np.mean(data_false),2)
mu_multiple = round(np.mean(data_true)/np.mean(data_false),1)

print("Reject null hypothesis; districts that receive 0 bids on one of their internet access services have higher cost/mbps than districts with only 1+ bid internet access services. P-value: {}".format(pvalue))
print("Mean cost/mbps for districts that receive 0 bids on one of their internet access services: ${}".format(mu_true))
print("Mean cost/mbps for districts that receive 1+ bids on all of their internet access services: ${}".format(mu_false))
print("Districts that receive 0 bids on one of their internet access services pay {}x as much as districts that only receive 1 or more bids".format(mu_multiple))


##plot cost/mbps
y = [mu_true, mu_false]
x = [1, 2]
axis_label = ['0 Bid FRNs', '1+ Bid FRNs']
width = 1/1.5

plt.bar(x, y, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Difference in Average     Internet Access Cost/Mbps', fontsize = 20)
plt.xticks(x, axis_label)
plt.ylabel('Internet Access cost/mbps')
plt.annotate("$"+str(mu_true), xy=(.9, mu_true + .9), xytext=(.9, mu_true + .9), color = "grey")
plt.annotate("$"+str(mu_false), xy=(1.9, mu_false + .9), xytext=(1.9, mu_false + .9), color = "grey")
plt.annotate(str(mu_multiple)+"x", xy=(1.5, (mu_true - mu_false)/2 + mu_false), xytext=(1.5, (mu_true - mu_false)/2 + mu_false), color = 'red', size = 20)
seaborn.despine(left=True, right=True)
seaborn.set_style("whitegrid", {'axes.grid' : False})
plt.show()
plt.savefig("figures/ia_cost_by_frn_bids.png")
