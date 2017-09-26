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


##------------------------------------------------------------------------------------------
## unnested data frame
udf = trigrams[['all_categories', 'frn_arrays']]
udf = udf.set_index('all_categories')
unnested_lst = []

for col in udf.columns:
    unnested_lst.append(udf['frn_arrays'].apply(pd.Series).stack())
result = pd.concat(unnested_lst, axis=1, keys=udf.columns)



fixed_category = result.index.get_level_values(0).astype(str)
fixed_category.name = 'fixed_category'
new_index = pd.MultiIndex.from_arrays([result.index.get_level_values(0), fixed_category])
result.index = new_index
result = result.reset_index(level = ['fixed_category'])
result = result.drop_duplicates()
result = pd.DataFrame(result.groupby(['frn_arrays'])['fixed_category'].apply(lambda x: x.sum()))
result['fixed_category'] = result['fixed_category'].apply(lambda x: re.sub('\\]\\[', ',', x))
result.index.name = 'frn'


print('-*_*_*_*_*_*_*_')
print(list(result))
print(result.index.name)
print(len(result))


##------------------------------------------------------------------------------------------
## merging unnested dataframe back to denied

denied = denied.merge(result, how = 'left', left_on = 'frn', right_index = True)
denied = denied[['frn', 'fcdl_comment_cleaned', 'fcdl_comment_array', 'trigram_array', 'fixed_category']]
#needs_cateogory = denied.dropna(subset = ['fixed_category'])
#needs_cateogory = needs_cateogory[['frn', 'fcdl_comment_cleaned', 'fcdl_comment_array', 'trigram_array', 'fixed_category']]

#print(len(needs_cateogory))

denied.to_csv('fcdl_data/still_needs_category.csv')
