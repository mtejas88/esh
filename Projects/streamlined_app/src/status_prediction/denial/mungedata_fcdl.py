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
frns_2016 = pd.read_csv('frns_2016.csv', encoding = "ISO-8859-1")
frns_2017 = pd.read_csv('frns_2017.csv', encoding = "ISO-8859-1")

os.chdir(GITHUB+'/Projects/streamlined_app/fcdl_data/') 
trigrams = pd.read_csv('trigrams_review_yubana_cleaned.csv')
frns_manual_cats = pd.read_csv('still_needs_category_yubana.csv')

##prep frns data for modeling
#model using cat 1 data only
frns_2016  = frns_2016.loc[frns_2016['category_of_service'] < 2]
frns_2017  = frns_2017.loc[frns_2017['category_of_service'] < 2]

#model without special construction apps only
frns_2016  = frns_2016.loc[frns_2016['special_construction_indicator'] < 1]
frns_2017  = frns_2017.loc[frns_2017['special_construction_indicator'] < 1]

#create original denial indicator utilizing indicator for if an FRN was funded but originally denied
frns_2016['orig_denied_frn'] = np.logical_or(frns_2016.denied_frn, frns_2016.appealed_funded_frn)
frns_2017['orig_denied_frn'] = np.logical_or(frns_2017.denied_frn, frns_2017.appealed_funded_frn)

#filter to those frns where the FRN doesn't have a pending or cancelled status
frns_2016_model  = frns_2016.loc[np.logical_or(frns_2016['funded_frn']> 0, frns_2016['denied_frn']>0)]
frns_2017_model  = frns_2017.loc[np.logical_or(frns_2017['funded_frn']> 0, frns_2017['denied_frn']>0)]

#append 2016 and 2017 frns
frns_model = pd.concat([frns_2016_model[['frn','orig_denied_frn', 'fcdl_comment_for_frn']], frns_2017_model[['frn', 'orig_denied_frn', 'fcdl_comment_for_frn']]], axis=0)

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

##prep trigram categorization for narrative analysis
#limit to only columns we need
trigrams_r1 = trigrams[['trigram', 'phrase_array', 'CATEGORY']]

#limit to only columns we need
trigrams_r2 = trigrams[['trigram', 'phrase_array', 'Other Notes']]

#rename columns for merge
trigrams_r2.columns = ['trigram', 'phrase_array', 'CATEGORY']

#limit to only categories we need
trigrams_r2 = trigrams_r2.loc[trigrams_r2.CATEGORY.notnull()]

#merge categorizations
trigrams_cats = pd.concat([trigrams_r1, trigrams_r2], axis=0)

#cleaning categorizations - missing documentation
trigrams_cats['CATEGORY'] = np.where(trigrams_cats['CATEGORY'].str.lower().str.startswith('missing documentation', na=False), 'Missing documentation', trigrams_cats['CATEGORY'])

#cleaning categorizations - ineligible service
trigrams_cats['CATEGORY'] = np.where(trigrams_cats['CATEGORY']=='Ineligible Service', 'Ineligible Services', trigrams_cats['CATEGORY'])

#cleaning categorizations - proper case
trigrams_cats['CATEGORY'] = trigrams_cats.CATEGORY.str.title()

#reset index
trigrams_cats = trigrams_cats.reset_index(drop=True)

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

##add manually categorized FRNs
#limit FRNs to only those manually categorized
frns_manual_cats = frns_manual_cats.loc[frns_manual_cats.Category.notnull()]

#limit to only columns we need
frns_manual_cats = frns_manual_cats[['frn', 'Category']]
frns_manual_cats.columns = ['frn', 'CATEGORY']

#cleaning categorizations - competitive bidding
frns_manual_cats['CATEGORY'] = np.where(frns_manual_cats['CATEGORY']=='Bid Evaluation Process', 'Competitive Bidding Violation', frns_manual_cats['CATEGORY'])

#cleaning categorizations - proper case
frns_manual_cats['CATEGORY'] = frns_manual_cats.CATEGORY.str.title()

#cleaning categorizations - remove approved / none
frns_manual_cats = frns_manual_cats.loc[np.logical_and(frns_manual_cats['CATEGORY'] != 'None', frns_manual_cats['CATEGORY'] != 'Approved')]
#create indicator for each category
category_dummies = pd.get_dummies(frns_manual_cats.CATEGORY, prefix='category')
frns_manual_cats = pd.concat([frns_manual_cats, category_dummies], axis=1)

#remove category columns
frns_manual_cats = frns_manual_cats.drop('CATEGORY', 1)

#append manual cats to trigram cats
frns_cats = pd.concat([frns_cats, frns_manual_cats], axis=0)

#turn nulls to 0s
frns_cats = frns_cats.fillna(value=0)

#aggregate indicators to FRN level
frns_cats = frns_cats.groupby('frn').mean()

#make sum into indicator
for col in frns_cats.columns:
  frns_cats[col] = np.where(frns_cats[col] > 0, 1, 0)

##save
os.chdir(GITHUB+'/Projects/streamlined_app/data/interim') 
frns_model.to_csv('frns_model.csv')
frns_cats.to_csv('frns_cats.csv')
