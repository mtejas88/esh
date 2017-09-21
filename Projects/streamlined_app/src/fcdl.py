import os
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/Projects/streamlined_app')

##packages
import pandas as pd
import numpy as np
import re
import string
from collections import Counter

##read csv
fcdl = pd.read_csv('fcdl_data/fcdl_raw.csv')

##see unique values of the frn statuses
print(fcdl['frn_status'].unique())

##set index
fcdl.set_index('frn')

##creating dataframe of denied comments
denied = fcdl[fcdl['frn_status'] == 'Denied'].copy()

##new - fix the settingwithcopy
denied.loc[:,'fcdl_comment_for_frn'].str.lower()
print('READ ME')
print(denied['fcdl_comment_for_frn'])
denied['test2'] = denied.fcdl_comment_for_frn.copy().str.lower()
#print(denied['test2'].head())

##making the comments lowercase
fcdl_comment_cleaned = denied['fcdl_comment_for_frn'].str.lower()

##removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

##removing punctuation
punct = re.compile('[%s]' % re.escape(string.punctuation))
def punct_re(s):
    return punct.sub(' ', s)
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(x))

##creating new column in dataframe that is the cleaned up text
denied['fcdl_comment_cleaned'] = fcdl_comment_cleaned

##creating a new columns array of all the words
denied['fcdl_comment_array'] = denied['fcdl_comment_cleaned'].apply(lambda x: x.split())

##removing stop words
from nltk.corpus import stopwords, PlaintextCorpusReader

stops = stopwords.words("english")

def remove_stops(text):
	return [item for item in text if item not in stops]

denied['fcdl_comment_array'] = denied['fcdl_comment_array'].apply(lambda x: remove_stops(x))

##re-creating the cleaned column after removing stop words
denied['fcdl_comment_cleaned'] = denied['fcdl_comment_array'].apply(lambda x: ' '.join(x))

#---------------------------------------------------------------------------------
from sklearn.feature_extraction.text import CountVectorizer

# Initialize the "CountVectorizer" object, which is scikit-learn's
# bag of words tool.  
vectorizer = CountVectorizer(analyzer = "word",   \
                             tokenizer = None,    \
                             preprocessor = None, \
                             stop_words = None,   \
                             max_features = 5000) 

# fit_transform() does two functions: First, it fits the model
# and learns the vocabulary; second, it transforms our training data
# into feature vectors. The input to fit_transform should be a list of 
# strings.
train_data_features = vectorizer.fit_transform(denied.loc[:,'fcdl_comment_cleaned'])

# Convert the result to an array
train_data_features = train_data_features.toarray()
vocab = vectorizer.get_feature_names()

# Sum up the counts of each vocabulary word
dist = np.sum(train_data_features, axis=0)

# For each, print the vocabulary word and the number of times it 
# appears in the training set
a = []
b = []
for tag, count in zip(vocab, dist):
    a.append(count)
    b.append(tag)

word_counts = pd.DataFrame({'text': b, 'count': a})
word_counts = word_counts.set_index('text')

print(word_counts.sort_values('count', ascending = False).head(20))

#---------------------------------------------------------------------------------
##bigrams & trigrams

from collections import Counter
from itertools import tee, islice

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

def ngrams2(comment, n):
  
  for i in range(0,len(comment)):
    grams = list()
    if i < (len(comment) - n + 1):
      grams.append(comment[i])
      counter = 0
      while counter < (n - 1):
        grams.append(comment[i + 1 + counter])
        counter += 1

  return grams
    


    #comment[i], comment[i + 1]


denied['bigram_array'] = denied['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 2)))
denied['bigram_array_test'] = denied['fcdl_comment_array'].apply(lambda x: ngrams2(x, 2))
print(denied.head())
denied['trigram_array'] = denied['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 3)))

##bigrams
all_bigrams = pd.Series()
for row in denied['bigram_array']:
  s = pd.Series(row, name = 'bigrams')
  all_bigrams = all_bigrams.append(s)

print(type(all_bigrams))
all_bigrams = pd.DataFrame(all_bigrams)

print('----------')
all_bigrams.index.names = ['bigram']
all_bigrams.columns = ['count']
all_bigrams = all_bigrams.groupby(['bigram']).sum()
print(all_bigrams.sort_values('count', ascending = False).head(20))

##trigrams
all_trigrams = pd.Series()
for row in denied['trigram_array']:
  t = pd.Series(row, name = 'trigrams')
  all_trigrams = all_trigrams.append(t)

print(type(all_trigrams))
all_trigrams = pd.DataFrame(all_trigrams)

print('----------')
all_trigrams.index.names = ['trigram']
all_trigrams.columns = ['count']
all_trigrams = all_trigrams.groupby(['trigram']).sum()
print(all_trigrams.sort_values('count', ascending = False).head(20))

print('result of new n grams with adrianna')
print(denied.iloc[0]['fcdl_comment_array'])
print(ngrams2(denied.iloc[0]['fcdl_comment_array'],2))

##---------------------------------------------------------------------------------
##write results to CSVs

word_counts.sort_values('count', ascending = False).to_csv('fcdl_data/single_words.csv')
all_bigrams.sort_values('count', ascending = False).to_csv('fcdl_data/bigrams.csv')
all_trigrams.sort_values('count', ascending = False).to_csv('fcdl_data/trigrams.csv')
