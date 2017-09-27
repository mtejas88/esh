##------------------------------------------------------------------------------------------
##SET UP

import os
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/Projects/streamlined_app')

##packages
import pandas as pd
import numpy as np
import re
import string
from collections import Counter

##------------------------------------------------------------------------------------------
##read and clean up csv

##read csv
yubana_review = pd.read_csv('fcdl_data/trigrams_review_yubana.csv')

yubana_review = yubana_review.set_index('trigram')
yubana_review = yubana_review.drop('#', axis = 1)
print(yubana_review.columns)

##changing text of None to the value None
yubana_review['CATEGORY'] = np.where(yubana_review['CATEGORY'] == 'None', None, yubana_review['CATEGORY'])

#removing certain phrases from the other notes column that shouldn't actually be new categories
print(yubana_review['Other Notes'].unique())
remove = ['not always (8)', 'Not mentioned in 470']
yubana_review['Other Notes'] = np.where(yubana_review['Other Notes'].isin(remove), None, yubana_review['Other Notes'])
yubana_review['Other Notes'] = np.where(yubana_review['Other Notes'].isnull(), None, yubana_review['Other Notes'])

##removing phrases that don't have a category
yubana_review = yubana_review[pd.notnull(yubana_review['CATEGORY'])]


##creating a column with all of the categories of the phrase (some of multiple categories)
yubana_review['all_categories'] = yubana_review[['CATEGORY', 'Other Notes']].values.tolist()

#yubana_review['all_categories'] = [x for x in yubana_review['all_categories']]
#yubana_review['all_categories'] = np.where(yubana_review['Other Notes'].isnull(), yubana_review['CATEGORY'], 'Other Test')

print(yubana_review.head())
print(yubana_review.iloc[0]['all_categories'][1] is None)

##------------------------------------------------------------------------------------------
## writing out csv
yubana_review.to_csv('fcdl_data/trigrams_review_yubana_cleaned.csv')