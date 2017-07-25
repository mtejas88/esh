##Aggregating data for export
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np

## summary all
#import model results
summ_110k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_110k_applications_c1_2017_approval_optimized.csv')
summ_110k_2017_approval_optimized ['year'] = 2017
summ_110k_2017_approval_optimized ['model'] = '110k approval'
summ_50k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2017_approval_optimized.csv')
summ_50k_2017_approval_optimized ['year'] = 2017
summ_50k_2017_approval_optimized ['model'] = '50k approval'
summ_50k_2017_denial_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2017_denial_optimized.csv')
summ_50k_2017_denial_optimized['year'] = 2017
summ_50k_2017_denial_optimized['model'] = '50k denial'
summ_25k_2017_approval_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2017_approval_optimized.csv')
summ_25k_2017_approval_optimized ['year'] = 2017
summ_25k_2017_approval_optimized ['model'] = '25k approval'
summ_25k_2017_denial_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2017_denial_optimized.csv')
summ_25k_2017_denial_optimized ['year'] = 2017
summ_25k_2017_denial_optimized ['model'] = '25k denial'

summ_110k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_110k_applications_c1_2016_approval_optimized.csv')
summ_110k_2016_approval_optimized ['year'] = 2016
summ_110k_2016_approval_optimized ['model'] = '110k approval'
summ_50k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2016_approval_optimized.csv')
summ_50k_2016_approval_optimized ['year'] = 2016
summ_50k_2016_approval_optimized ['model'] = '50k approval'
summ_50k_2016_denial_optimized = pd.read_csv('data/interim/summ_lowcost_50k_applications_c1_2016_denial_optimized.csv')
summ_50k_2016_denial_optimized['year'] = 2016
summ_50k_2016_denial_optimized['model'] = '50k denial'
summ_25k_2016_approval_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2016_approval_optimized.csv')
summ_25k_2016_approval_optimized ['year'] = 2016
summ_25k_2016_approval_optimized ['model'] = '25k approval'
summ_25k_2016_denial_optimized = pd.read_csv('data/interim/summ_lowcost_25k_applications_c1_2016_denial_optimized.csv')
summ_25k_2016_denial_optimized ['year'] = 2016
summ_25k_2016_denial_optimized ['model'] = '25k denial'

#import actual values
summ_2016 = pd.read_csv('data/raw/c1_summary_2016.csv')
summ_2017 = pd.read_csv('data/raw/c1_summary_2017.csv')

#append
summ = summ_110k_2017_approval_optimized.append([summ_50k_2017_approval_optimized, summ_50k_2017_denial_optimized, summ_25k_2017_approval_optimized, summ_25k_2017_denial_optimized, summ_110k_2016_approval_optimized, summ_50k_2016_approval_optimized, summ_50k_2016_denial_optimized, summ_25k_2016_approval_optimized, summ_25k_2016_denial_optimized, summ_2016, summ_2017], ignore_index=True) 

#export
summ.to_csv('data/processed/results_summary.csv')

## summary as discussed
# total c1
total_c1_vert =  summ.loc[summ['model'] == 'all actual'].groupby('year').agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'sum'})
total_c1_vert['label'] = 'Total C1'
total_c1_vert['model'] = 'n/a'
total_c1_2016 = total_c1_vert.loc[total_c1_vert.index == 2016]
total_c1_2017 = total_c1_vert.loc[total_c1_vert.index == 2017]
total_c1_2016 = total_c1_2016.reset_index()
total_c1_2017 = total_c1_2017.reset_index()
total_c1 = pd.concat([total_c1_2016, total_c1_2017], axis=1, join='inner')
total_c1=total_c1.T.drop_duplicates().T
total_c1.columns = ['year_2016', 'total_funding_year_commitment_amount_request_2016', 'application_number_2016', 'label', 'model', 'year_2017', 'total_funding_year_commitment_amount_request_2017', 'application_number_2017']

# total c1 low cost
lowcost_c1_vert =  summ.loc[summ['model'] != 'all actual'].groupby(['model','year']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'sum'})
lowcost_c1_vert['label'] = 'Low Cost C1'
lowcost_c1_vert = lowcost_c1_vert.reset_index(level = 'year')
lowcost_c1_2016 = lowcost_c1_vert.loc[lowcost_c1_vert['year'] == 2016]
lowcost_c1_2017 = lowcost_c1_vert.loc[lowcost_c1_vert['year'] == 2017]
lowcost_c1 = pd.concat([lowcost_c1_2016, lowcost_c1_2017], axis=1, join='inner')
lowcost_c1 = lowcost_c1.reset_index(level = 'model')
lowcost_c1=lowcost_c1.T.drop_duplicates().T
lowcost_c1.columns = ['model', 'year_2016', 'total_funding_year_commitment_amount_request_2016', 'application_number_2016', 'label', 'year_2017', 'total_funding_year_commitment_amount_request_2017', 'application_number_2017']

# total c1 low cost approvals
lowcost_c1_approvals_vert =  summ.loc[summ['yhat'] == 0]
lowcost_c1_approvals_vert = lowcost_c1_approvals_vert.ix[:, lowcost_c1_approvals_vert.columns != 'yhat']
lowcost_c1_approvals_vert['label'] = 'Low Cost C1 Approvals'
lowcost_c1_approvals_2016 = lowcost_c1_approvals_vert.loc[lowcost_c1_approvals_vert['year'] == 2016]
lowcost_c1_approvals_2017 = lowcost_c1_approvals_vert.loc[lowcost_c1_approvals_vert['year'] == 2017]
lowcost_c1_approvals_2016 = lowcost_c1_approvals_2016.reset_index()
lowcost_c1_approvals_2017 = lowcost_c1_approvals_2017.reset_index()
lowcost_c1_approvals = pd.concat([lowcost_c1_approvals_2016, lowcost_c1_approvals_2017], axis=1, join='inner')
lowcost_c1_approvals=lowcost_c1_approvals.T.drop_duplicates().T
lowcost_c1_approvals = lowcost_c1_approvals.ix[:, lowcost_c1_approvals.columns != 'index']
lowcost_c1_approvals.columns = ['total_funding_year_commitment_amount_request_2016', 'application_number_2016', 'year_2016', 'model', 'label', 'total_funding_year_commitment_amount_request_2017', 'application_number_2017', 'year_2017']


# total c1 low cost denials
lowcost_c1_denials_vert =  summ.loc[summ['yhat'] == 1]
lowcost_c1_denials_vert = lowcost_c1_denials_vert.ix[:, lowcost_c1_denials_vert.columns != 'yhat']
lowcost_c1_denials_vert['label'] = 'Low Cost C1 Denials'
lowcost_c1_denials_2016 = lowcost_c1_denials_vert.loc[lowcost_c1_denials_vert['year'] == 2016]
lowcost_c1_denials_2017 = lowcost_c1_denials_vert.loc[lowcost_c1_denials_vert['year'] == 2017]
lowcost_c1_denials_2016 = lowcost_c1_denials_2016.reset_index()
lowcost_c1_denials_2017 = lowcost_c1_denials_2017.reset_index()
lowcost_c1_denials = pd.concat([lowcost_c1_denials_2016, lowcost_c1_denials_2017], axis=1, join='inner')
lowcost_c1_denials=lowcost_c1_denials.T.drop_duplicates().T
lowcost_c1_denials = lowcost_c1_denials.ix[:, lowcost_c1_denials.columns != 'index']
lowcost_c1_denials.columns = ['total_funding_year_commitment_amount_request_2016', 'application_number_2016', 'year_2016', 'model', 'label', 'total_funding_year_commitment_amount_request_2017', 'application_number_2017', 'year_2017']

#append and reorganize
summ_2 = lowcost_c1.append([lowcost_c1_approvals, lowcost_c1_denials], ignore_index=True) 

#remove unnecessary rows
summ_2 = summ_2.loc[summ_2['model'] != 'all actual']
summ_2 = summ_2.loc[np.logical_not(np.logical_and(summ_2['model'].str.contains('approval'),summ_2['label'] == 'Low Cost C1'))]
summ_2 = summ_2.loc[np.logical_not(np.logical_and(summ_2['model'].str.contains('denial'),summ_2['label'] == 'Low Cost C1'))]

#sort and append more
summ_2 = summ_2.sort_values(['model', 'label'])
summ_2 = total_c1.append(summ_2, ignore_index=True)

#rename columns and remove unnecessary rows
summ_2 = summ_2.ix[:,['model', 'label', 'application_number_2016', 'total_funding_year_commitment_amount_request_2016', 'application_number_2017', 'total_funding_year_commitment_amount_request_2017']]

#replace values that don't make sense
summ_2['label'] = np.where(np.logical_and(np.logical_not(summ_2['model'].str.contains('actual')),summ_2['label'] == 'Low Cost C1 Denials'), 'Low Cost C1 Approvals could be Denials', summ_2['label'] )

summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'].str.contains('actual'),summ_2['label'] != 'Low Cost C1'), 'N/A', summ_2['application_number_2017'] )
summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'].str.contains('actual'),summ_2['label'] != 'Low Cost C1'), 'N/A', summ_2['total_funding_year_commitment_amount_request_2017'] )

#calculating errors
data_110_approval_2016 = pd.read_csv('data/interim/lowcost_110k_applications_c1_2016_approval_optimized.csv')
error_110_approval_2016 = data_110_approval_2016.groupby(['yhat', 'denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
error_110_approval_2016 = error_110_approval_2016.reset_index()
error_110_approval_2016 = error_110_approval_2016.loc[np.logical_and(error_110_approval_2016['yhat'] == 0, error_110_approval_2016['denied_indicator'] == 1)]

data_50_approval_2016 = pd.read_csv('data/interim/lowcost_50k_applications_c1_2016_approval_optimized.csv')
error_50_approval_2016 = data_50_approval_2016.groupby(['yhat', 'denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
error_50_approval_2016 = error_50_approval_2016.reset_index()
error_50_approval_2016 = error_50_approval_2016.loc[np.logical_and(error_50_approval_2016['yhat'] == 0, error_50_approval_2016['denied_indicator'] == 1)]

data_50_denial_2016 = pd.read_csv('data/interim/lowcost_50k_applications_c1_2016_denial_optimized.csv')
error_50_denial_2016 = data_50_denial_2016.groupby(['yhat', 'denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
error_50_denial_2016 = error_50_denial_2016.reset_index()
error_50_denial_2016 = error_50_denial_2016.loc[np.logical_and(error_50_denial_2016['yhat'] == 0, error_50_denial_2016['denied_indicator'] == 1)]

data_25_approval_2016 = pd.read_csv('data/interim/lowcost_25k_applications_c1_2016_approval_optimized.csv')
error_25_approval_2016 = data_25_approval_2016.groupby(['yhat', 'denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
error_25_approval_2016 = error_25_approval_2016.reset_index()
error_25_approval_2016 = error_25_approval_2016.loc[np.logical_and(error_25_approval_2016['yhat'] == 0, error_25_approval_2016['denied_indicator'] == 1)]

data_25_denial_2016 = pd.read_csv('data/interim/lowcost_25k_applications_c1_2016_denial_optimized.csv')
error_25_denial_2016 = data_25_denial_2016.groupby(['yhat', 'denied_indicator']).agg({'total_funding_year_commitment_amount_request': 'sum', 'application_number': 'count'})
error_25_denial_2016  = error_25_denial_2016 .reset_index()
error_25_denial_2016  = error_25_denial_2016 .loc[np.logical_and(error_25_denial_2016 ['yhat'] == 0, error_25_denial_2016 ['denied_indicator'] == 1)]

cm_110_approval = np.loadtxt('data/interim/sm_lowcost_110k_applications_c1_approval_optimized.out', delimiter=',')
pct_110_approval= cm_110_approval[0,1]/(cm_110_approval[0,1]+cm_110_approval[0,0])

cm_50_approval = np.loadtxt('data/interim/sm_lowcost_50k_applications_c1_approval_optimized.out', delimiter=',')
pct_50_approval= cm_50_approval[0,1]/(cm_50_approval[0,1]+cm_50_approval[0,0])

cm_50_denial = np.loadtxt('data/interim/sm_lowcost_50k_applications_c1_denial_optimized.out', delimiter=',')
pct_50_denial = cm_50_denial[0,1]/(cm_50_denial[0,1]+cm_50_denial[0,0])

cm_25_approval = np.loadtxt('data/interim/sm_lowcost_25k_applications_c1_approval_optimized.out', delimiter=',')
pct_25_approval= cm_25_approval[0,1]/(cm_25_approval[0,1]+cm_25_approval[0,0])

cm_25_denial = np.loadtxt('data/interim/sm_lowcost_25k_applications_c1_denial_optimized.out', delimiter=',')
pct_25_denial = cm_25_denial[0,1]/(cm_25_denial[0,1]+cm_25_denial[0,0])


#subbing in more values that don't make sense
summ_2['total_funding_year_commitment_amount_request_2016'] = np.where(np.logical_and(summ_2['model'] == '110k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_110_approval_2016.total_funding_year_commitment_amount_request, summ_2['total_funding_year_commitment_amount_request_2016'] )
summ_2['application_number_2016'] = np.where(np.logical_and(summ_2['model'] == '110k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_110_approval_2016.application_number, summ_2['application_number_2016'] )

summ_2['total_funding_year_commitment_amount_request_2016'] = np.where(np.logical_and(summ_2['model'] == '50k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_50_approval_2016.total_funding_year_commitment_amount_request, summ_2['total_funding_year_commitment_amount_request_2016'] )
summ_2['application_number_2016'] = np.where(np.logical_and(summ_2['model'] == '50k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_50_approval_2016.application_number, summ_2['application_number_2016'] )

summ_2['total_funding_year_commitment_amount_request_2016'] = np.where(np.logical_and(summ_2['model'] == '50k denial', summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_50_denial_2016.total_funding_year_commitment_amount_request, summ_2['total_funding_year_commitment_amount_request_2016'] )
summ_2['application_number_2016'] = np.where(np.logical_and(summ_2['model'] == '50k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_50_denial_2016.application_number, summ_2['application_number_2016'] )

summ_2['total_funding_year_commitment_amount_request_2016'] = np.where(np.logical_and(summ_2['model'] == '25k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_25_approval_2016.total_funding_year_commitment_amount_request, summ_2['total_funding_year_commitment_amount_request_2016'] )
summ_2['application_number_2016'] = np.where(np.logical_and(summ_2['model'] == '25k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_25_approval_2016.application_number, summ_2['application_number_2016'] )

summ_2['total_funding_year_commitment_amount_request_2016'] = np.where(np.logical_and(summ_2['model'] == '25k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_25_denial_2016.total_funding_year_commitment_amount_request, summ_2['total_funding_year_commitment_amount_request_2016'] )
summ_2['application_number_2016'] = np.where(np.logical_and(summ_2['model'] == '25k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), error_25_denial_2016.application_number, summ_2['application_number_2016'] )

summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'] == '25k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_25_denial, summ_2['total_funding_year_commitment_amount_request_2017'] )
summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'] == '25k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_25_denial, summ_2['application_number_2017'] )

summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'] == '25k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_25_approval, summ_2['total_funding_year_commitment_amount_request_2017'] )
summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'] == '25k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_25_approval, summ_2['application_number_2017'] )

summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'] == '50k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_50_approval, summ_2['total_funding_year_commitment_amount_request_2017'] )
summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'] == '50k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_50_approval, summ_2['application_number_2017'] )

summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'] == '50k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_50_denial, summ_2['total_funding_year_commitment_amount_request_2017'] )
summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'] == '50k denial',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_50_denial, summ_2['application_number_2017'] )

summ_2['total_funding_year_commitment_amount_request_2017'] = np.where(np.logical_and(summ_2['model'] == '110k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_110_approval, summ_2['total_funding_year_commitment_amount_request_2017'] )
summ_2['application_number_2017'] = np.where(np.logical_and(summ_2['model'] == '110k approval',summ_2['label'] == 'Low Cost C1 Approvals could be Denials'), pct_110_approval, summ_2['application_number_2017'] )


#export
summ_2.to_csv('data/processed/results_summary_presentation.csv')


