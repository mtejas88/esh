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

#adapeted from https://github.com/educationsuperhighway/ficher/blob/master/Projects/streamlined_app/src/fcdl.py
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
frns_2017 = pd.read_csv('frns_2017_approval_optimized.csv', encoding = "ISO-8859-1")
frns_2016 = pd.read_csv('frns_2016_approval_optimized.csv', encoding = "ISO-8859-1")
trigrams_cats = pd.read_csv('trigrams_cats.csv', encoding = "ISO-8859-1")

##prep frns data for modeling
#filter to false approvals
frns_2016  = frns_2016.loc[np.logical_and(frns_2016['yhat'] == 0, frns_2016['orig_denied_frn'] == 1)]
frns_2017  = frns_2017.loc[np.logical_and(frns_2017['yhat'] == 0, frns_2017['orig_denied_frn'] == 1)]

#append 2016 and 2017 frns
frns = pd.concat([frns_2016, frns_2017], axis=0)

#reset index
frns = frns.reset_index(drop=True)

##prep frns data for narrative analysis
#adapted from https://github.com/educationsuperhighway/ficher/blob/master/Projects/streamlined_app/src/evan_fcdl.py

#making the narrative lowercase
fcdl_comment_cleaned = frns['fcdl_comment_for_frn'].str.lower()

#removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

#removing punctuation
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(str(x)))

#creating new column in dataframe that is the cleaned up text
frns['fcdl_comment_cleaned'] = fcdl_comment_cleaned

#creating a new columns array of all the words
frns['fcdl_comment_array'] = frns['fcdl_comment_cleaned'].apply(lambda x: x.split())

#removing stop words
frns['fcdl_comment_array'] = frns['fcdl_comment_array'].apply(lambda x: remove_stops(x))

#re-creating the cleaned column after removing stop words
frns['fcdl_comment_cleaned'] = frns['fcdl_comment_array'].apply(lambda x: ' '.join(x))

##prep frns for trigrams categorization
#note: code takes 30 sec - 1 min

#create counter array of all trigrams in narrative
frns['trigram_array'] = frns['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 3)))

#create empty array to fill with all categorized FRNs
frn_cats = pd.DataFrame(columns=['CATEGORY', 'frn'])

#create range for which to loop through FRNS
index_frn_cats = range(0,len(frns))

#for each FRN, create a dataframe of the possible categories
for j in index_frn_cats:

  #create empty array which will serve as a placeholder for each FRNs categories
  cats = []

  #create empty array which will serve as a placeholder for each FRNs categories
  index_cats = range(0,len(trigrams_cats))

  #for each category, convert trigram to tuple in order to check if that trigram is in the narrative
  for i in index_cats:
    cats.append(tuple(re.findall(r"[\w]+", trigrams_cats['trigram'][i])) in frns['trigram_array'][j])

  #convert to data frame
  cats = pd.DataFrame(data=cats, index=index_cats, columns=['in_array'])
  
  #add the category for each trigram for reference
  cats = pd.concat([cats, trigrams_cats[['CATEGORY']]], axis=1)
  
  #add the FRN for each loop for reference
  cats['frn'] = frns['frn'][j]
  
  #filter to categories that are in the array
  cats = cats.loc[cats.in_array == True]
  
  #filter to columns we want to record
  cats = cats[['CATEGORY', 'frn']]
  
  #drop duplicated categories
  cats = cats.drop_duplicates()
  
  #append daraframe to all other FRNs recorded
  frn_cats = pd.concat([frn_cats, cats], axis=0)

#reset index of final dataframe
frn_cats = frn_cats.reset_index(drop = True)

##merge trigrams categorizations with frns data
#create indicator for each category
category_dummies = pd.get_dummies(frn_cats.CATEGORY, prefix='category')
frn_cats = pd.concat([frn_cats, category_dummies], axis=1)

#aggregate indicators to FRN level
frns_cats = frn_cats.groupby('frn').sum()

#make sum into indicator
for col in frns_cats.columns:
  frns_cats[col] = np.where(frns_cats[col] > 0, 1, 0)

#reset index for merge
frns_cats = frns_cats.reset_index()


##save
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 
frns_cats.to_csv('false_approval_frns_cats.csv')