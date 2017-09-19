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
denied = fcdl[fcdl['frn_status'] == 'Denied']

##making the comments lowercase
denied['test'] = denied['fcdl_comment_for_frn']
fcdl_comment_cleaned = denied['fcdl_comment_for_frn'].str.lower()

##removing trailing and leading whitespaces
fcdl_comment_cleaned = fcdl_comment_cleaned.str.strip()

##removing punctuation
punct = re.compile('[%s]' % re.escape(string.punctuation))
def punct_re(s):
    return punct.sub(' ', s)
fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: punct_re(x))

##---------------------------------------------------------------------------------
##spell checker..seems intense
##source: https://github.com/norvig/pytudes/blob/master/spell.py
def words(text): return re.findall(r'\w+', text.lower())

WORDS = Counter(words(open('fcdl_data/big.txt').read()))

def P(word, N=sum(WORDS.values())): 
    "Probability of `word`."
    return WORDS[word] / N

def correction(word): 
    "Most probable spelling correction for word."
    return max(candidates(word), key=P)

def candidates(word): 
    "Generate possible spelling corrections for word."
    return (known([word]) or known(edits1(word)) or known(edits2(word)) or [word])

def known(words): 
    "The subset of `words` that appear in the dictionary of WORDS."
    return set(w for w in words if w in WORDS)

def edits1(word):
    "All edits that are one edit away from `word`."
    letters    = 'abcdefghijklmnopqrstuvwxyz'
    splits     = [(word[:i], word[i:])    for i in range(len(word) + 1)]
    deletes    = [L + R[1:]               for L, R in splits if R]
    transposes = [L + R[1] + R[0] + R[2:] for L, R in splits if len(R)>1]
    replaces   = [L + c + R[1:]           for L, R in splits if R for c in letters]
    inserts    = [L + c + R               for L, R in splits for c in letters]
    return set(deletes + transposes + replaces + inserts)

def edits2(word): 
    "All edits that are two edits away from `word`."
    return (e2 for e1 in edits1(word) for e2 in edits1(e1))

print(correction('speling'))
print(correction('korrectud'))
print(correction('kajsfaslkfj'))

#fcdl_comment_cleaned = fcdl_comment_cleaned.apply(lambda x: correction(x))

#---------------------------------------------------------------------------------


denied['fcdl_comment_cleaned'] = fcdl_comment_cleaned


#print(denied.iloc[0]['fcdl_comment_for_frn'])
print('---------------------')
print(denied.iloc[0]['fcdl_comment_cleaned'])

##USE re.search to find if it exists at all (result.group(0) is the string is found)

##removing stop words
from nltk.corpus import stopwords, PlaintextCorpusReader

stops = stopwords.words("english")
#print(stops)
#words = [w for w in denied.loc[:,'fcdl_comment_cleaned'] if not w in stops]

denied['fcdl_comment_array'] = denied['fcdl_comment_cleaned'].apply(lambda x: x.split())

def remove_stops(text):
	return [item for item in text if item not in stops]

print(remove_stops(['this', 'is', 'in', 'a', 'jeremy', 'hello']))

print('pre stops')
print(denied.iloc[0]['fcdl_comment_array'])
denied['fcdl_comment_array'] = denied['fcdl_comment_array'].apply(lambda x: remove_stops(x))
print('post stops')
print(denied.iloc[0]['fcdl_comment_array'])


denied['fcdl_comment_cleaned'] = denied['fcdl_comment_array'].apply(lambda x: ' '.join(x))
print(denied.iloc[0]['fcdl_comment_cleaned'])


#---------------------------------------------------------------------------------
print("Creating the bag of words...\n")
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

# Numpy arrays are easy to work with, so convert the result to an 
# array
train_data_features = train_data_features.toarray()
print(train_data_features.shape)
vocab = vectorizer.get_feature_names()
#print(vocab)

# Sum up the counts of each vocabulary word
dist = np.sum(train_data_features, axis=0)

# For each, print the vocabulary word and the number of times it 
# appears in the training set
##Add this back
a = []
b = []
for tag, count in zip(vocab, dist):
    a.append(count)
    b.append(tag)

word_counts = pd.DataFrame({'text': b, 'num': a})

print(word_counts.sort_values('num', ascending = False).head(20))

#---------------------------------------------------------------------------------
##bigrams

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

test = re.findall("\w+", 
   "the quick person did not realize his speed and the quick person bumped")

print(Counter(ngrams(test, 3)))

denied['bigram_array'] = denied['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 2)))
denied['trigram_array'] = denied['fcdl_comment_array'].apply(lambda x: Counter(ngrams(x, 3)))

print(denied.iloc[0]['bigram_array'])
print('-----------')
print(denied.iloc[0]['trigram_array'])

all_bigrams = pd.DataFrame.from_dict(denied['bigram_array'], orient='index')

