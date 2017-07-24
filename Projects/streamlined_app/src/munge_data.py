##Indicators for regression
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np

## data prep
#import
applications = pd.read_csv('data/raw/applications_2016_contd.csv')

#create indicators
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10

applications['denied_indicator'] = np.where(applications['denied_frns'] > 0, 1, 0)
applications['denied_indicator_py'] = np.where(applications['denied_frns_15'] > 0, 1, 0)

applications['1bids_indicator'] = np.where(applications['num_frns_1_bids'] > 0, 1, 0)
applications['0bids_indicator'] = np.where(applications['num_frns_0_bids'] > 0, 1, 0)
applications['prevyear_indicator'] = np.where(applications['num_frns_from_previous_year'] > 0, 1, 0)
applications['mastercontract_indicator'] = np.where(applications['num_frns_state_master_contract'] > 0, 1, 0)
applications['no_consultant_indicator'] = np.where(applications['consultant_indicator'] == False, 1, 0)

den = applications.groupby('denied_indicator')
print(den.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

applicant_type_dummies = pd.get_dummies(applications.applicant_type, prefix='applicant_type')
applications = pd.concat([applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(applications.urban_rural_status, prefix='locale')
applications = pd.concat([applications, locale_dummies], axis=1)

category_dummies = pd.get_dummies(applications.category_of_service, prefix='category')
applications = pd.concat([applications, category_dummies], axis=1)

applications['maintenance_indicator'] = np.where(applications['service_types'].str.contains('Basic Maintenance'), 1, 0)
applications['connections_indicator'] = np.where(applications['service_types'].str.contains('Internal Connections'), 1, 0)
applications['managedbb_indicator'] = np.where(applications['service_types'].str.contains('Managed Internal Broadband Services'), 1, 0)
applications['voice_indicator'] = np.where(applications['service_types'].str.contains('Voice'), 1, 0)
applications['datatrans_indicator'] = np.where(applications['service_types'].str.contains('Data Transmission'), 1, 0)
applications['fiber_indicator'] = np.where(applications['functions'].str.contains('Fiber'), 1, 0)
applications['copper_indicator'] = np.where(applications['functions'].str.contains('Copper'), 1, 0)
applications['wireless_indicator'] = np.where(applications['functions'].str.contains('Wireless'), 1, 0)
applications['isp_indicator'] = np.where(applications['purposes'].str.contains('ISP'), 1, 0)
applications['upstream_indicator'] = np.where(applications['purposes'].str.contains('Upstream'), 1, 0)
applications['internet_indicator'] = np.where(applications['purposes'].str.contains('Internet'), 1, 0)
applications['wan_indicator'] = np.where(applications['purposes'].str.contains('WAN'), 1, 0)
applications['backbone_indicator'] = np.where(applications['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
applications['min_contract_expiry_date'] = np.where(applications['min_contract_expiry_date'] == '06/30/3017', '06/30/2017', applications['min_contract_expiry_date'])
applications['min_contract_expiry_date'] = np.where(applications['min_contract_expiry_date'] == '09/30/3017', '09/30/2017', applications['min_contract_expiry_date'])

applications['min_contract_expiry_date'] = pd.to_datetime(applications['min_contract_expiry_date'])    
applications['min_contract_expiry_date_delta'] = (applications['min_contract_expiry_date'] - applications['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '06/30/3019', '06/30/2019', applications['max_contract_expiry_date'])
applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '06/30/3018', '06/30/2018', applications['max_contract_expiry_date'])
applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '06/30/3017', '06/30/2017', applications['max_contract_expiry_date'])
applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '09/30/3017', '09/30/2017', applications['max_contract_expiry_date'])
applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '06/30/3016', '06/30/2016', applications['max_contract_expiry_date'])
applications['max_contract_expiry_date'] = np.where(applications['max_contract_expiry_date'] == '06/30/2917', '06/30/2017', applications['max_contract_expiry_date'])

applications['max_contract_expiry_date'] = pd.to_datetime(applications['max_contract_expiry_date'])    
applications['max_contract_expiry_date_delta'] = (applications['max_contract_expiry_date'] - applications['max_contract_expiry_date'].min())  / np.timedelta64(1,'D')

applications['certified_timestamp'] = pd.to_datetime(applications['certified_timestamp'])    
applications['certified_timestamp_delta'] = (applications['certified_timestamp'] - applications['certified_timestamp'].min())  / np.timedelta64(1,'D')

#lowcost indicators
applications['lowcost_25k_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications['lowcost_50k_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 50000, True, False)
applications['lowcost_110k_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 110000, True, False)

applications  = applications.loc[applications['frns'] == applications['funded_frns'] + applications['denied_frns']]
lowcost_25k_applications  = applications.loc[applications['lowcost_25k_indicator'] == True]
lowcost_50k_applications  = applications.loc[applications['lowcost_50k_indicator'] == True]
lowcost_110k_applications  = applications.loc[applications['lowcost_110k_indicator'] == True]

lowcost_25k_applications.to_csv('data/interim/lowcost_25k_applications.csv')
lowcost_50k_applications.to_csv('data/interim/lowcost_50k_applications.csv')
lowcost_110k_applications.to_csv('data/interim/lowcost_110k_applications.csv')

## 2017 data prep
#import
applications_2017 = pd.read_csv('data/raw/applications_2017_contd.csv')

#create indicators
applications_2017['discount_category'] = np.floor(applications_2017['category_one_discount_rate']/10)*10

applications_2017['denied_indicator'] = np.where(applications_2017['denied_frns'] > 0, 1, 0)
applications_2017['denied_indicator_py'] = np.where(applications_2017['denied_frns_16'] > 0, 1, 0)

applicant_type_dummies = pd.get_dummies(applications_2017.applicant_type, prefix='applicant_type')
applications_2017 = pd.concat([applications_2017, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(applications_2017.urban_rural_status, prefix='locale')
applications_2017 = pd.concat([applications_2017, locale_dummies], axis=1)

applications_2017['copper_indicator'] = np.where(applications_2017['functions'].str.contains('Copper'), 1, 0)
applications_2017['internet_indicator'] = np.where(applications_2017['purposes'].str.contains('Internet'), 1, 0)
applications_2017['backbone_indicator'] = np.where(applications_2017['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
applications_2017['min_contract_expiry_date'] = np.where(applications_2017['min_contract_expiry_date'] == '6/30/3018', '06/30/2018', applications_2017['min_contract_expiry_date'])

applications_2017['min_contract_expiry_date'] = pd.to_datetime(applications_2017['min_contract_expiry_date'])    
applications_2017['min_contract_expiry_date_delta'] = (applications_2017['min_contract_expiry_date'] - applications_2017['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

# categories
category_dummies = pd.get_dummies(applications_2017.category_of_service, prefix='category')
applications_2017 = pd.concat([applications_2017, category_dummies], axis=1)

#lowcost indicators

applications_2017['lowcost_25k_indicator'] = np.where(applications_2017['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications_2017['lowcost_50k_indicator'] = np.where(applications_2017['total_funding_year_commitment_amount_request'] < 50000, True, False)
applications_2017['lowcost_110k_indicator'] = np.where(applications_2017['total_funding_year_commitment_amount_request'] < 110000, True, False)

lowcost_25k_applications_2017  = applications_2017.loc[applications_2017['lowcost_25k_indicator'] == True]
lowcost_50k_applications_2017 = applications_2017.loc[applications_2017['lowcost_50k_indicator'] == True]
lowcost_110k_applications_2017 = applications_2017.loc[applications_2017['lowcost_110k_indicator'] == True]

lowcost_25k_applications_2017.to_csv('data/interim/lowcost_25k_applications_2017.csv')
lowcost_50k_applications_2017.to_csv('data/interim/lowcost_50k_applications_2017.csv')
lowcost_110k_applications_2017.to_csv('data/interim/lowcost_110k_applications_2017.csv')

