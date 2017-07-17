##Determining significant factors for cost and plotting cost diff for consultant
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np

## data prep
#import
applications = pd.read_csv('data/raw/applications_2016_contd.csv')

#create indicators
applications['lowcost_indicator'] = np.where(applications['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10

lowcost_applications  = applications.loc[applications['frns'] == applications['funded_frns'] + applications['denied_frns']]
lowcost_applications  = lowcost_applications.loc[lowcost_applications['lowcost_indicator'] == True]

lowcost_applications['denied_indicator'] = np.where(lowcost_applications['denied_frns'] > 0, 1, 0)
lowcost_applications['denied_indicator_py'] = np.where(lowcost_applications['denied_frns_15'] > 0, 1, 0)

lowcost_applications['1bids_indicator'] = np.where(lowcost_applications['num_frns_1_bids'] > 0, 1, 0)
lowcost_applications['0bids_indicator'] = np.where(lowcost_applications['num_frns_0_bids'] > 0, 1, 0)
lowcost_applications['prevyear_indicator'] = np.where(lowcost_applications['num_frns_from_previous_year'] > 0, 1, 0)
lowcost_applications['mastercontract_indicator'] = np.where(lowcost_applications['num_frns_state_master_contract'] > 0, 1, 0)
lowcost_applications['no_consultant_indicator'] = np.where(lowcost_applications['consultant_indicator'] == False, 1, 0)

den = lowcost_applications.groupby('denied_indicator')
print(den.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

applicant_type_dummies = pd.get_dummies(lowcost_applications.applicant_type, prefix='applicant_type')
lowcost_applications = pd.concat([lowcost_applications, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(lowcost_applications.urban_rural_status, prefix='locale')
lowcost_applications = pd.concat([lowcost_applications, locale_dummies], axis=1)

category_dummies = pd.get_dummies(lowcost_applications.category_of_service, prefix='category')
lowcost_applications = pd.concat([lowcost_applications, category_dummies], axis=1)

lowcost_applications['maintenance_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Basic Maintenance'), 1, 0)
lowcost_applications['connections_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Internal Connections'), 1, 0)
lowcost_applications['managedbb_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Managed Internal Broadband Services'), 1, 0)
lowcost_applications['voice_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Voice'), 1, 0)
lowcost_applications['datatrans_indicator'] = np.where(lowcost_applications['service_types'].str.contains('Data Transmission'), 1, 0)
lowcost_applications['fiber_indicator'] = np.where(lowcost_applications['functions'].str.contains('Fiber'), 1, 0)
lowcost_applications['copper_indicator'] = np.where(lowcost_applications['functions'].str.contains('Copper'), 1, 0)
lowcost_applications['wireless_indicator'] = np.where(lowcost_applications['functions'].str.contains('Wireless'), 1, 0)
lowcost_applications['isp_indicator'] = np.where(lowcost_applications['purposes'].str.contains('ISP'), 1, 0)
lowcost_applications['upstream_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Upstream'), 1, 0)
lowcost_applications['internet_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Internet'), 1, 0)
lowcost_applications['wan_indicator'] = np.where(lowcost_applications['purposes'].str.contains('WAN'), 1, 0)
lowcost_applications['backbone_indicator'] = np.where(lowcost_applications['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
lowcost_applications['min_contract_expiry_date'] = np.where(lowcost_applications['min_contract_expiry_date'] == '06/30/3017', '06/30/2017', lowcost_applications['min_contract_expiry_date'])

lowcost_applications['min_contract_expiry_date'] = pd.to_datetime(lowcost_applications['min_contract_expiry_date'])    
lowcost_applications['min_contract_expiry_date_delta'] = (lowcost_applications['min_contract_expiry_date'] - lowcost_applications['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3019', '06/30/2019', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3018', '06/30/2018', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3017', '06/30/2017', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/3016', '06/30/2016', lowcost_applications['max_contract_expiry_date'])
lowcost_applications['max_contract_expiry_date'] = np.where(lowcost_applications['max_contract_expiry_date'] == '06/30/2917', '06/30/2017', lowcost_applications['max_contract_expiry_date'])

lowcost_applications['max_contract_expiry_date'] = pd.to_datetime(lowcost_applications['max_contract_expiry_date'])    
lowcost_applications['max_contract_expiry_date_delta'] = (lowcost_applications['max_contract_expiry_date'] - lowcost_applications['max_contract_expiry_date'].min())  / np.timedelta64(1,'D')

lowcost_applications['certified_timestamp'] = pd.to_datetime(lowcost_applications['certified_timestamp'])    
lowcost_applications['certified_timestamp_delta'] = (lowcost_applications['certified_timestamp'] - lowcost_applications['certified_timestamp'].min())  / np.timedelta64(1,'D')

lowcost_applications.to_csv('data/interim/lowcost_applications_contd.csv')

## 2017 data prep
#import
applications_2017 = pd.read_csv('data/raw/applications_2017_contd.csv')

#create indicators
applications_2017['lowcost_indicator'] = np.where(applications_2017['total_funding_year_commitment_amount_request'] < 25000, True, False)
applications_2017['discount_category'] = np.floor(applications_2017['category_one_discount_rate']/10)*10

#lowcost_applications_2017  = applications_2017.loc[applications_2017['frns'] == applications_2017['funded_frns'] + applications_2017['denied_frns']]
lowcost_applications_2017  = applications_2017.loc[applications_2017['lowcost_indicator'] == True]

lowcost_applications_2017['denied_indicator'] = np.where(lowcost_applications_2017['denied_frns'] > 0, 1, 0)
lowcost_applications_2017['denied_indicator_py'] = np.where(lowcost_applications_2017['denied_frns_16'] > 0, 1, 0)

applicant_type_dummies = pd.get_dummies(lowcost_applications_2017.applicant_type, prefix='applicant_type')
lowcost_applications_2017 = pd.concat([lowcost_applications_2017, applicant_type_dummies], axis=1)

locale_dummies = pd.get_dummies(lowcost_applications_2017.urban_rural_status, prefix='locale')
lowcost_applications_2017 = pd.concat([lowcost_applications_2017, locale_dummies], axis=1)

lowcost_applications_2017['copper_indicator'] = np.where(lowcost_applications_2017['functions'].str.contains('Copper'), 1, 0)
lowcost_applications_2017['internet_indicator'] = np.where(lowcost_applications_2017['purposes'].str.contains('Internet'), 1, 0)
lowcost_applications_2017['backbone_indicator'] = np.where(lowcost_applications_2017['purposes'].str.contains('Backbone'), 1, 0)

#convert dates to deltas
lowcost_applications_2017['min_contract_expiry_date'] = np.where(lowcost_applications_2017['min_contract_expiry_date'] == '6/30/3018', '06/30/2018', lowcost_applications_2017['min_contract_expiry_date'])

lowcost_applications_2017['min_contract_expiry_date'] = pd.to_datetime(lowcost_applications_2017['min_contract_expiry_date'])    
lowcost_applications_2017['min_contract_expiry_date_delta'] = (lowcost_applications_2017['min_contract_expiry_date'] - lowcost_applications_2017['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

# categories
category_dummies = pd.get_dummies(lowcost_applications_2017.category_of_service, prefix='category')
lowcost_applications_2017 = pd.concat([lowcost_applications_2017, category_dummies], axis=1)

lowcost_applications_2017.to_csv('data/interim/lowcost_applications_2017_contd.csv')