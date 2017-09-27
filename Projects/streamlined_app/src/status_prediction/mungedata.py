##imports and definitions
#packages
import pandas as pd
import numpy as np

#import environment variables
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

#import data
os.chdir(GITHUB+'/Projects/streamlined_app/data/raw') 
applications_2016 = pd.read_csv('applications_2016_contd.csv')
applications_2017 = pd.read_csv('applications_2017_contd.csv')
frns_2016 = pd.read_csv('frns_2016.csv', encoding = "ISO-8859-1")
frns_2017 = pd.read_csv('frns_2017.csv', encoding = "ISO-8859-1")

## 2016 FRN data prep
#discount category
frns_2016['discount_category'] = np.floor(frns_2016['category_one_discount_rate']/10)*10

#applicant type
applicant_type_dummies = pd.get_dummies(frns_2016.applicant_type, prefix='applicant_type')
frns_2016 = pd.concat([frns_2016, applicant_type_dummies], axis=1)

#applicant denied previously
frns_2016['denied_indicator_py'] = np.where(frns_2016['denied_frns_py'] > 0, 1, 0)

#locale
locale_dummies = pd.get_dummies(frns_2016.urban_rural_status, prefix='locale')
frns_2016 = pd.concat([frns_2016, locale_dummies], axis=1)

#type of service
service_dummies = pd.get_dummies(frns_2016.service_type, prefix='service')
frns_2016 = pd.concat([frns_2016, service_dummies], axis=1)

#type of service
frns_2016['fiber_indicator'] = np.where(frns_2016['functions'].str.contains('Fiber'), 1, 0)
frns_2016['copper_indicator'] = np.where(frns_2016['functions'].str.contains('Copper'), 1, 0)
frns_2016['wireless_indicator'] = np.where(frns_2016['functions'].str.contains('Wireless'), 1, 0)
frns_2016['isp_indicator'] = np.where(frns_2016['purposes'].str.contains('ISP'), 1, 0)
frns_2016['upstream_indicator'] = np.where(frns_2016['purposes'].str.contains('Upstream'), 1, 0)
frns_2016['internet_indicator'] = np.where(frns_2016['purposes'].str.contains('Internet'), 1, 0)
frns_2016['wan_indicator'] = np.where(frns_2016['purposes'].str.contains('WAN'), 1, 0)
frns_2016['backbone_indicator'] = np.where(frns_2016['purposes'].str.contains('Backbone'), 1, 0)

## 2017 FRN data prep
#discount category
frns_2017['discount_category'] = np.floor(frns_2017['category_one_discount_rate']/10)*10

#applicant type
applicant_type_dummies = pd.get_dummies(frns_2017.applicant_type, prefix='applicant_type')
frns_2017 = pd.concat([frns_2017, applicant_type_dummies], axis=1)

#applicant denied previously
frns_2017['denied_indicator_py'] = np.where(frns_2017['denied_frns_py'] > 0, 1, 0)

#locale
locale_dummies = pd.get_dummies(frns_2017.urban_rural_status, prefix='locale')
frns_2017 = pd.concat([frns_2017, locale_dummies], axis=1)

#type of service
service_dummies = pd.get_dummies(frns_2017.service_type, prefix='service')
frns_2017 = pd.concat([frns_2017, service_dummies], axis=1)

#type of service
frns_2017['fiber_indicator'] = np.where(frns_2017['functions'].str.contains('Fiber'), 1, 0)
frns_2017['copper_indicator'] = np.where(frns_2017['functions'].str.contains('Copper'), 1, 0)
frns_2017['wireless_indicator'] = np.where(frns_2017['functions'].str.contains('Wireless'), 1, 0)
frns_2017['isp_indicator'] = np.where(frns_2017['purposes'].str.contains('ISP'), 1, 0)
frns_2017['upstream_indicator'] = np.where(frns_2017['purposes'].str.contains('Upstream'), 1, 0)
frns_2017['internet_indicator'] = np.where(frns_2017['purposes'].str.contains('Internet'), 1, 0)
frns_2017['wan_indicator'] = np.where(frns_2017['purposes'].str.contains('WAN'), 1, 0)
frns_2017['backbone_indicator'] = np.where(frns_2017['purposes'].str.contains('Backbone'), 1, 0)


##2016 application data prep
#discount category
applications_2016['discount_category'] = np.floor(applications_2016['category_one_discount_rate']/10)*10

#application denied
applications_2016['denied_indicator'] = np.where(applications_2016['denied_frns'] > 0, 1, 0)
applications_2016['appealed_funded_indicator'] = np.where(applications_2016['appealed_funded_frns'] > 0, 1, 0)
applications_2016['denied_indicator_py'] = np.where(applications_2016['denied_frns_15'] > 0, 1, 0)

#number of bids
applications_2016['1bids_indicator'] = np.where(applications_2016['num_frns_1_bids'] > 0, 1, 0)
applications_2016['0bids_indicator'] = np.where(applications_2016['num_frns_0_bids'] > 0, 1, 0)

#FRN applied for in previous year
applications_2016['prevyear_indicator'] = np.where(applications_2016['num_frns_from_previous_year'] > 0, 1, 0)

#FRN is of master contract
applications_2016['mastercontract_indicator'] = np.where(applications_2016['num_frns_state_master_contract'] > 0, 1, 0)

#FRN has consultant
applications_2016['no_consultant_indicator'] = np.where(applications_2016['consultant_indicator'] == False, 1, 0)

#applicant type
applicant_type_dummies = pd.get_dummies(applications_2016.applicant_type, prefix='applicant_type')
applications_2016 = pd.concat([applications_2016, applicant_type_dummies], axis=1)

#locale
locale_dummies = pd.get_dummies(applications_2016.urban_rural_status, prefix='locale')
applications_2016 = pd.concat([applications_2016, locale_dummies], axis=1)

#type of service
applications_2016['maintenance_indicator'] = np.where(applications_2016['service_types'].str.contains('Basic Maintenance'), 1, 0)
applications_2016['connections_indicator'] = np.where(applications_2016['service_types'].str.contains('Internal Connections'), 1, 0)
applications_2016['managedbb_indicator'] = np.where(applications_2016['service_types'].str.contains('Managed Internal Broadband Services'), 1, 0)
applications_2016['voice_indicator'] = np.where(applications_2016['service_types'].str.contains('Voice'), 1, 0)
applications_2016['datatrans_indicator'] = np.where(applications_2016['service_types'].str.contains('Data Transmission'), 1, 0)
applications_2016['fiber_indicator'] = np.where(applications_2016['functions'].str.contains('Fiber'), 1, 0)
applications_2016['copper_indicator'] = np.where(applications_2016['functions'].str.contains('Copper'), 1, 0)
applications_2016['wireless_indicator'] = np.where(applications_2016['functions'].str.contains('Wireless'), 1, 0)
applications_2016['isp_indicator'] = np.where(applications_2016['purposes'].str.contains('ISP'), 1, 0)
applications_2016['upstream_indicator'] = np.where(applications_2016['purposes'].str.contains('Upstream'), 1, 0)
applications_2016['internet_indicator'] = np.where(applications_2016['purposes'].str.contains('Internet'), 1, 0)
applications_2016['wan_indicator'] = np.where(applications_2016['purposes'].str.contains('WAN'), 1, 0)
applications_2016['backbone_indicator'] = np.where(applications_2016['purposes'].str.contains('Backbone'), 1, 0)

#date cleaning -- min contract expiry date
applications_2016['min_contract_expiry_date'] = np.where(applications_2016['min_contract_expiry_date'] == '06/30/3017', '06/30/2017', applications_2016['min_contract_expiry_date'])
applications_2016['min_contract_expiry_date'] = np.where(applications_2016['min_contract_expiry_date'] == '09/30/3017', '09/30/2017', applications_2016['min_contract_expiry_date'])

#date conversion -- min contract expiry date
applications_2016['min_contract_expiry_date'] = pd.to_datetime(applications_2016['min_contract_expiry_date'])    
applications_2016['min_contract_expiry_date_delta'] = (applications_2016['min_contract_expiry_date'] - applications_2016['min_contract_expiry_date'].min())  / np.timedelta64(1,'D')

#date cleaning -- min contract expiry date
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '06/30/3019', '06/30/2019', applications_2016['max_contract_expiry_date'])
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '06/30/3018', '06/30/2018', applications_2016['max_contract_expiry_date'])
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '06/30/3017', '06/30/2017', applications_2016['max_contract_expiry_date'])
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '09/30/3017', '09/30/2017', applications_2016['max_contract_expiry_date'])
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '06/30/3016', '06/30/2016', applications_2016['max_contract_expiry_date'])
applications_2016['max_contract_expiry_date'] = np.where(applications_2016['max_contract_expiry_date'] == '06/30/2917', '06/30/2017', applications_2016['max_contract_expiry_date'])

#date conversion -- min contract expiry date
applications_2016['max_contract_expiry_date'] = pd.to_datetime(applications_2016['max_contract_expiry_date'])    
applications_2016['max_contract_expiry_date_delta'] = (applications_2016['max_contract_expiry_date'] - applications_2016['max_contract_expiry_date'].min())  / np.timedelta64(1,'D')

#date conversion -- certified timestamp
applications_2016['certified_timestamp'] = pd.to_datetime(applications_2016['certified_timestamp'])    
applications_2016['certified_timestamp_delta'] = (applications_2016['certified_timestamp'] - applications_2016['certified_timestamp'].min())  / np.timedelta64(1,'D')

## 2017 application data prep
#discount category
applications_2017['discount_category'] = np.floor(applications_2017['category_one_discount_rate']/10)*10

#application denied
applications_2017['denied_indicator'] = np.where(applications_2017['denied_frns'] > 0, 1, 0)
applications_2017['appealed_funded_indicator'] = np.where(applications_2017['appealed_funded_frns'] > 0, 1, 0)
applications_2017['denied_indicator_py'] = np.where(applications_2017['denied_frns_16'] > 0, 1, 0)

#number of bids
applications_2017['1bids_indicator'] = np.where(applications_2017['num_frns_1_bids'] > 0, 1, 0)
applications_2017['0bids_indicator'] = np.where(applications_2017['num_frns_0_bids'] > 0, 1, 0)

#applicant type
applicant_type_dummies = pd.get_dummies(applications_2017.applicant_type, prefix='applicant_type')
applications_2017 = pd.concat([applications_2017, applicant_type_dummies], axis=1)

#locale
locale_dummies = pd.get_dummies(applications_2017.urban_rural_status, prefix='locale')
applications_2017 = pd.concat([applications_2017, locale_dummies], axis=1)

#type of service
applications_2017['managedbb_indicator'] = np.where(applications_2017['service_types'].str.contains('Managed Internal Broadband Services'), 1, 0)
applications_2017['voice_indicator'] = np.where(applications_2017['service_types'].str.contains('Voice'), 1, 0)
applications_2017['datatrans_indicator'] = np.where(applications_2017['service_types'].str.contains('Data Transmission'), 1, 0)
applications_2017['fiber_indicator'] = np.where(applications_2017['functions'].str.contains('Fiber'), 1, 0)
applications_2017['copper_indicator'] = np.where(applications_2017['functions'].str.contains('Copper'), 1, 0)
applications_2017['wireless_indicator'] = np.where(applications_2017['functions'].str.contains('Wireless'), 1, 0)
applications_2017['isp_indicator'] = np.where(applications_2017['purposes'].str.contains('ISP'), 1, 0)
applications_2017['upstream_indicator'] = np.where(applications_2017['purposes'].str.contains('Upstream'), 1, 0)
applications_2017['internet_indicator'] = np.where(applications_2017['purposes'].str.contains('Internet'), 1, 0)
applications_2017['wan_indicator'] = np.where(applications_2017['purposes'].str.contains('WAN'), 1, 0)
applications_2017['backbone_indicator'] = np.where(applications_2017['purposes'].str.contains('Backbone'), 1, 0)


##save
#source of raw data
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 

#save files
frns_2016.to_csv('frns_2016.csv')
frns_2017.to_csv('frns_2017.csv')
print("2016 and 2017 FRNs saved")

applications_2016.to_csv('applications_2016.csv')
applications_2017.to_csv('applications_2017.csv')
print("2016 and 2017 applications saved")
