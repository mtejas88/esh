##imports and definitions
#import packages
import pandas as pd
import numpy as np
import re
import string
from collections import Counter
from nltk.corpus import stopwords, PlaintextCorpusReader
from itertools import tee, islice

#import environment variables
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

#define classes
punct = re.compile('[%s]' % re.escape(string.punctuation))
def punct_re(s):
    return punct.sub(' ', s)

stops = stopwords.words("english")
def remove_stops(text):
    return [item for item in text if item not in stops]

def ngrams(lst, n):
  tlst = lst
  while True:
    a, b = tee(tlst)
    l = tuple(islice(a, n))
    if len(l) == n:
      yield l
      next(b)
      tlst = b
    else:
      break

#import data
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 
frns_2016 = pd.read_csv('frns_2016.csv', encoding = "ISO-8859-1")
frns_2017 = pd.read_csv('frns_2017.csv', encoding = "ISO-8859-1")

os.chdir(GITHUB+'/Projects/streamlined_app/fcdl_data/') 
trigrams = pd.read_csv('trigrams_review_yubana_cleaned.csv')

##prep frns data for modeling
#model using cat 1 data only
frns_2016  = frns_2016.loc[frns_2016['category_of_service'] < 2]
frns_2017  = frns_2017.loc[frns_2017['category_of_service'] < 2]

#model without special construction apps only
frns_2016  = frns_2016.loc[frns_2016['special_construction_indicator'] < 1]
frns_2017  = frns_2017.loc[frns_2017['special_construction_indicator'] < 1]

#filter to those frns where none of the FRNS have a pending or cancelled status
frns_2016_model  = frns_2016.loc[np.logical_or(frns_2016['funded_frn']> 0, frns_2016['denied_frn'])>0]
frns_2017_model  = frns_2017.loc[np.logical_or(frns_2017['funded_frn']> 0, frns_2017['denied_frn'])>0]

#append 2016 and 2017 frns
frns_model = pd.concat([frns_2016_model[['frn','denied_frn', 'fcdl_comment_for_frn']], frns_2017_model[['frn', 'denied_frn', 'fcdl_comment_for_frn']]], axis=0)

#reset index
frns_model = frns_model.reset_index(drop=True)

##prep frns data for narrative analysis
#adapted from https://github.com/educationsuperhighway/ficher/blob/master/Projects/streamlined_app/src/evan_fcdl.py

#making the narrative lowercase
fcdl_comment_cleaned = frns_model['fcdl_comment_for_frn'].str.lower()

#removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

#removing punctuation
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(str(x)))

#creating new column in dataframe that is the cleaned up text
frns_model['fcdl_comment_cleaned'] = fcdl_comment_cleaned

#creating a new columns array of all the words
frns_model['fcdl_comment_array'] = frns_model['fcdl_comment_cleaned'].apply(lambda x: x.split())

#removing stop words
frns_model['fcdl_comment_array'] = frns_model['fcdl_comment_array'].apply(lambda x: remove_stops(x))

#re-creating the cleaned column after removing stop words
frns_model['fcdl_comment_cleaned'] = frns_model['fcdl_comment_array'].apply(lambda x: ' '.join(x))

##prep frns for trigrams
#adapeted from https://github.com/educationsuperhighway/ficher/blob/master/Projects/streamlined_app/src/fcdl.py
frns_model['trigram_array'] = frns_model['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 3)))
frns_trigrams = frns_model[['frn', 'trigram_array']]

##prep trigram categorization for narrative analysis
#first trigram category
trigrams_r1 = trigrams[['trigram', 'phrase_array', 'CATEGORY']]

trigrams_r2 = trigrams[['trigram', 'phrase_array', 'Other Notes']]
trigrams_r2.columns = ['trigram', 'phrase_array', 'CATEGORY']
trigrams_r2 = trigrams_r2.loc[trigrams_r2.CATEGORY.notnull()]

trigrams_cats = pd.concat([trigrams_r1, trigrams_r2], axis=0)


##save
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 
frns_model.to_csv('frns_model.csv')
