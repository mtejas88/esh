import os
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/Projects/streamlined_app')

##packages
import pandas as pd
import numpy as np
import re
import string
from collections import Counter

##read csv
evan_review = pd.read_csv('fcdl_data/evan_review.csv')

##set index
evan_review.set_index('ID')

##see unique values of categorized denial reasons
#print(evan_review['DR1'].unique())

##making the narrative lowercase
fcdl_comment_cleaned = evan_review['Denial Narratives for FRNs'].str.lower()

##removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

##removing punctuation
punct = re.compile('[%s]' % re.escape(string.punctuation))
def punct_re(s):
    return punct.sub(' ', s)
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(x))

##creating new column in dataframe that is the cleaned up text
evan_review['fcdl_comment_cleaned'] = fcdl_comment_cleaned

##creating a new columns array of all the words
evan_review['fcdl_comment_array'] = evan_review['fcdl_comment_cleaned'].apply(lambda x: x.split())

##removing stop words
from nltk.corpus import stopwords, PlaintextCorpusReader

stops = stopwords.words("english")

def remove_stops(text):
	return [item for item in text if item not in stops]

evan_review['fcdl_comment_array'] = evan_review['fcdl_comment_array'].apply(lambda x: remove_stops(x))

##re-creating the cleaned column after removing stop words
evan_review['fcdl_comment_cleaned'] = evan_review['fcdl_comment_array'].apply(lambda x: ' '.join(x))

evan_review.to_csv('fcdl_data/evan_review_cleaned.csv')
