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
os.chdir(GITHUB+'/Projects/erate_defense/data/') 
frns_2016 = pd.read_csv('frns_2016.csv', encoding = "ISO-8859-1")
frns_2017 = pd.read_csv('frns_2017.csv', encoding = "ISO-8859-1")



#filter to those frns where the FRN doesn't have a pending or cancelled status
frns_2016_model  = frns_2016.loc[np.logical_or(frns_2016['funded_frn']> 0, frns_2016['denied_frn']>0)]
frns_2017_model  = frns_2017.loc[np.logical_or(frns_2017['funded_frn']> 0, frns_2017['denied_frn']>0)]


#reset index
frns_model = frns_model.reset_index(drop=True)

##prep frns data for narrative analysis
#adapted from https://github.com/educationsuperhighway/ficher/blob/master/Projects/streamlined_app/src/evan_fcdl.py
#only determine denial category for those that were originally denied
frns_denied = frns_model.loc[frns_model.orig_denied_frn == 1].copy()

#reset index
frns_denied = frns_denied.reset_index(drop = True)

#making the narrative lowercase
fcdl_comment_cleaned = frns_denied['fcdl_comment_for_frn'].str.lower()

#removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

#removing punctuation
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(str(x)))

#creating new column in dataframe that is the cleaned up text
frns_denied['fcdl_comment_cleaned'] = fcdl_comment_cleaned

#creating a new columns array of all the words
frns_denied['fcdl_comment_array'] = frns_denied['fcdl_comment_cleaned'].apply(lambda x: x.split())

#removing stop words
frns_denied['fcdl_comment_array'] = frns_denied['fcdl_comment_array'].apply(lambda x: remove_stops(x))

#re-creating the cleaned column after removing stop words
frns_denied['fcdl_comment_cleaned'] = frns_denied['fcdl_comment_array'].apply(lambda x: ' '.join(x))


##prep frns for trigrams categorization
#note: code takes 30 sec - 1 min

#create counter array of all trigrams in narrative
frns_denied['trigram_array'] = frns_denied['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 3)))

#create empty array to fill with all categorized FRNs
frn_cats = pd.DataFrame(columns=['CATEGORY', 'frn'])

#create range for which to loop through FRNS
index_frn_cats = range(0,len(frns_denied))

#for each FRN, create a dataframe of the possible categories
for j in index_frn_cats:

  #create empty array which will serve as a placeholder for each FRNs categories
  cats = []

  #create empty array which will serve as a placeholder for each FRNs categories
  index_cats = range(0,len(trigrams_cats))

  #for each category, convert trigram to tuple in order to check if that trigram is in the narrative
  for i in index_cats:
    cats.append(tuple(re.findall(r"[\w]+", trigrams_cats['trigram'][i])) in frns_denied['trigram_array'][j])

  #convert to data frame
  cats = pd.DataFrame(data=cats, index=index_cats, columns=['in_array'])
  
  #add the category for each trigram for reference
  cats = pd.concat([cats, trigrams_cats[['CATEGORY']]], axis=1)
  
  #add the FRN for each loop for reference
  cats['frn'] = frns_denied['frn'][j]
  
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
