##------------------------------------------------------------------------------------------
##SET UP

import os
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/Projects/streamlined_app')

##packages
import pandas as pd
import numpy as np
import re

##------------------------------------------------------------------------------------------
##read CSVs

##read csv
denied = pd.read_csv('fcdl_data/denied_data.csv')
trigrams = pd.read_csv('fcdl_data/trigrams_review_yubana_cleaned.csv')


##Adding the FRNs to all of the trigrams
def frns(word):
	frns = []
	for index, row in denied.iterrows():
	#for review in evan_review['fcdl_comment_cleaned']:
		if not(re.search(word, row['fcdl_comment_cleaned'])==None):
			frns.append(row['frn'])
		else:
			pass

	return frns


trigrams['frn_arrays'] = trigrams['phrase_array'].apply(lambda x: frns(x))

#print(denied.head())
print('-------------------')
#print(trigrams.head())

##------------------------------------------------------------------------------------------
## unnested data frame
udf = trigrams[['all_categories', 'frn_arrays']]
udf = udf.set_index('all_categories')
unnested_lst = []

for col in udf.columns:
    unnested_lst.append(udf['frn_arrays'].apply(pd.Series).stack())
result = pd.concat(unnested_lst, axis=1, keys=udf.columns)

result = result.drop_duplicates()

#category = result.index.get_level_values(0).astype(str)
#new_index = pd.MultiIndex.from_arrays([result.index.get_level_values(0), category])

#result.index = new_index
#result = result.set_index(new_index, drop = True)
fixed_category = result.index.get_level_values(0).astype(str)
fixed_category.name = 'fixed_category'
new_index = pd.MultiIndex.from_arrays([result.index.get_level_values(0), fixed_category])
result.index = new_index
result = result.reset_index(level = ['fixed_category'])
#result = result.reset_index('test', drop = False)
#result = result.reset_index(level = ['all_categories'], inplace = True)


print('-*_*_*_*_*_*_*_')
#print(result.head())
print(list(result))
print(len(result))


##------------------------------------------------------------------------------------------
## merging unnested dataframe back to denied

denied = denied.merge(result, how = 'left', left_on = 'frn', right_on = 'frn_arrays')
denied = denied[['frn', 'fcdl_comment_cleaned', 'fcdl_comment_array', 'trigram_array', 'fixed_category']]
#needs_cateogory = denied.dropna(subset = ['fixed_category'])
#needs_cateogory = needs_cateogory[['frn', 'fcdl_comment_cleaned', 'fcdl_comment_array', 'trigram_array', 'fixed_category']]

#print(len(needs_cateogory))

denied.to_csv('fcdl_data/still_needs_category.csv')

