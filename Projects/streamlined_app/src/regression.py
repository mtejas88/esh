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

## data prep
#import
applications_2016 = pd.read_csv('data/raw/applications_2016.csv')
applications_2017 = pd.read_csv('data/raw/applications_2017.csv')

applications_2016['funding_year'] = '2016'
applications_2017['funding_year'] = '2017'

applications_2017['funded_frns'] = ''
applications_2017['denied_frns'] = ''
applications_2017['frns'] = ''
applications_2017['avg_wave_number'] = ''

applications = pd.concat([applications_2017, applications_2016])
applications['lowcost'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)

##below not updated
##regression for consultant indicator
# modeling prep
applicant_type_dummies = pd.get_dummies(applications.applicant_type, prefix='applicant_type')
applications = pd.concat([applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(applications.urban_rural_status, prefix='locale')
applications = pd.concat([applications, locale_dummies], axis=1)

feature_cols = ['total_funding_year_commitment_amount_request', 'special_construction_indicator', 'num_service_types', 'num_spins', 'num_recipients', 'applicant_type_Consortium', 'applicant_type_Library', 'applicant_type_Library System', 'applicant_type_School', 'applicant_type_School District',  'category_of_service', 'locale_Urban', 'locale_Rural', 'category_one_discount_rate', 'fulltime_enrollment']

X = applications[feature_cols]
y = applications.consultant_indicator

# regression model
X = sm.add_constant(X)
est = sm.OLS(y, X.astype(float)).fit()
print(est.summary())

##plot requested per student
#calculate median requested/student
data_true = applications.loc[applications['consultant_indicator'] == True]
data_true = data_true.cost_per_student

data_false = applications.loc[applications['consultant_indicator'] == False]
data_false = data_false.cost_per_student

median_true = round(np.median(data_true),2)
median_false = round(np.median(data_false),2)
median_multiple = round(np.median(data_true)/np.median(data_false),1)

#plot median requested/student
y = [median_true, median_false]
x = [1, 2]
axis_label = ['Consultant', 'No Consultant']
width = 1/1.5

plt.bar(x, y, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Difference in Median\nFunding Request/Student', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('Funding request/student')
plt.annotate("$"+str(median_true), xy=(.9, median_true + .2), xytext=(.9, median_true + .2), color = "grey")
plt.annotate("$"+str(median_false), xy=(1.9, median_false + .2), xytext=(1.9, median_false + .2), color = "grey")
plt.annotate(str(median_multiple)+"x", xy=(1.5, (median_true - median_false)/2 + median_false), xytext=(1.5, (median_true - median_false)/2 + median_false), color = 'red', size = 20)
plt.show()
plt.savefig("figures/median_requested_per_student_by_consultant_usage.png")

##plot median requested
#calculate median requested
data_true = applications.loc[applications['consultant_indicator'] == True]
data_true = data_true.total_funding_year_commitment_amount_request

data_false = applications.loc[applications['consultant_indicator'] == False]
data_false = data_false.total_funding_year_commitment_amount_request

median_true = round(np.median(data_true),2)
median_false = round(np.median(data_false),2)
median_multiple = round(np.median(data_true)/np.median(data_false),1)

#plot median requested
y = [median_true, median_false]
x = [1, 2]
axis_label = ['Consultant', 'No Consultant']
width = 1/1.5

plt.bar(x, y, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Difference in Median\nFunding Request', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('Funding request')
plt.annotate("$"+str(median_true), xy=(.9, median_true + .2), xytext=(.9, median_true + .2), color = "grey")
plt.annotate("$"+str(median_false), xy=(1.9, median_false + .2), xytext=(1.9, median_false + .2), color = "grey")
plt.annotate(str(median_multiple)+"x", xy=(1.5, (median_true - median_false)/2 + median_false), xytext=(1.5, (median_true - median_false)/2 + median_false), color = 'red', size = 20)
plt.show()
plt.savefig("figures/median_requested_by_consultant_usage.png")


##plot sum requested
#calculate sum requested
sum_true = round(np.sum(data_true),-8)/1000000000
sum_false = round(np.sum(data_false),-8)/1000000000
sum_multiple = round(np.sum(data_true)/np.sum(data_false),1)

#plot sum requested
y = [sum_true, sum_false]
x = [1, 2]
axis_label = ['Consultant', 'No Consultant']
width = 1/1.5

plt.bar(x, y, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Difference in \nFunding Request', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('Funding request ($B)')
plt.annotate("$"+str(sum_true), xy=(.9, sum_true + .01), xytext=(.9, sum_true + .01), color = "grey")
plt.annotate("$"+str(sum_false), xy=(1.9, sum_false + .01), xytext=(1.9, sum_false + .01), color = "grey")
plt.annotate(str(sum_multiple)+"x", xy=(1.5, (sum_true - sum_false)/2 + sum_false), xytext=(1.5, (sum_true - sum_false)/2 + sum_false), color = 'red', size = 20)
plt.show()
plt.savefig("figures/requested_by_consultant_usage.png")

##regression for high funding request
feature_cols = ['consultant_indicator', 'special_construction_indicator', 'num_service_types', 'num_spins', 'num_recipients', 'applicant_type_Consortium', 'applicant_type_Library', 'applicant_type_Library System', 'applicant_type_School', 'applicant_type_School District',  'category_of_service', 'locale_Urban', 'locale_Rural', 'category_one_discount_rate', 'fulltime_enrollment']

X = applications[feature_cols]
y = applications.total_funding_year_commitment_amount_request

# regression model
X = sm.add_constant(X)
est = sm.OLS(y, X.astype(float)).fit()
print(est.summary())