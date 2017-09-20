import os
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/Projects/streamlined_app')

##packages
import pandas as pd
import numpy as np
import re
import string
from collections import Counter

##read csv
evan_review = pd.read_csv('fcdl_data/evan_review_cleaned.csv')
word_counts = pd.read_csv('fcdl_data/single_words.csv')
all_bigrams = pd.read_csv('fcdl_data/bigrams.csv')
all_trigrams = pd.read_csv('fcdl_data/trigrams.csv')


#word_counts['category_arrays'] = ''
#word_counts['category_arrays'] = word_counts['category_arrays'].apply(list)

print(word_counts.head())

#for word in word_counts.iloc[0:300]['text']:
	#for review in evan_review['fcdl_comment_cleaned']:
	#	if not(re.search(word, review)==None):
			#print(word,' is found in ', review)
			#print(word,' is has the category -- ', review)
	#		pass

print(evan_review['DR1'].unique())

def evan_categories(word):
	categories = []
	for index, row in evan_review.iterrows():
	#for review in evan_review['fcdl_comment_cleaned']:
		if not(re.search(word, row['fcdl_comment_cleaned'])==None) and not(row['DR1'] in categories):
			categories.append(row['DR1'])
		else:
			pass

	return categories

word_counts['category_arrays'] = word_counts['text'].apply(lambda x: evan_categories(x))

#print('---AFTER---')
print(word_counts.iloc[0]['category_arrays'])
#print(evan_review.head())

#for index, row in evan_review.iterrows():
#	print(row['DR1'])

