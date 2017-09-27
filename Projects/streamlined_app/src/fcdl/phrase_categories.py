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

def evan_ids(word):
	ids = []
	for index, row in evan_review.iterrows():
	#for review in evan_review['fcdl_comment_cleaned']:
		if not(re.search(word, row['fcdl_comment_cleaned'])==None) and not(row['DR1'] in ids):
			ids.append(row['ID'])
		else:
			pass

	return ids

word_counts['category_arrays'] = word_counts['text'].apply(lambda x: evan_categories(x))

def evan_categories_grams(phrase):
	categories = []
	phrase_adj = ' '.join(phrase)
	for index, row in evan_review.iterrows():
		if not(re.search(phrase_adj, row['fcdl_comment_cleaned'])==None) and not(row['DR1'] in categories):
			categories.append(row['DR1'])
		else:
			pass

	return categories

def clean(phrase):
	phrase = re.sub("\\'", '', phrase)
	phrase = re.sub("\\(", '', phrase)
	phrase = re.sub("\\)", '', phrase)
	phrase = re.sub("\\,", '', phrase)
	return phrase


all_bigrams['phrase_array'] = all_bigrams.bigram.apply(lambda x: clean(x))
all_trigrams['phrase_array'] = all_trigrams.trigram.apply(lambda x: clean(x))

#all_bigrams['consolidated_phrase'] = all_bigrams['bigram'].str.join(',')
all_bigrams['category_arrays'] = all_bigrams['phrase_array'].apply(lambda x: evan_categories(x))
all_trigrams['category_arrays'] = all_trigrams['phrase_array'].apply(lambda x: evan_categories(x))
all_trigrams['evan_ids'] = all_trigrams['phrase_array'].apply(lambda x: evan_ids(x))
print(all_bigrams.head())
print(all_trigrams.head())

word_counts.to_csv('fcdl_data/single_words_final.csv')
all_bigrams.to_csv('fcdl_data/bigrams_final.csv')
all_trigrams.to_csv('fcdl_data/trigrams_final.csv')