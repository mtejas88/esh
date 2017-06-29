
# coding: utf-8

# ![title](DataKind_orange_small.png)
# 

# ------------

# # TITLE: ESH Data Review

# # Summary
# 
# In this file DK reviewed the data. Not all exploration is recoreded but things that inlfuenced featurization are included. We used this notebooks a sort of exploration scratch pad - there may not be immediate need for ESH to review and use this notebook but some of the code or summaries may prove useful. 

# ----

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ----------

# # Initial Setup and Data Loading

# In[1]:

import sys
import os
import psycopg2
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import math
from collections import Counter
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",151)
get_ipython().magic(u'matplotlib inline')


# ## Local Helper Functions

# In[3]:

def summary(df):
    summary_list = []
    print 'SHAPE', df.shape
    
    for i in df.columns:
        vals = df[i]    
        if df[i].dtype == 'O':
            try:
                most_frequent = Counter(df[i].tolist()).most_common(1)
                uniq = vals.nunique()
            except TypeError:
                most_frequent = 'NA'
                uniq = 'NA'
            summary_list.append([i,vals.dtype, 'NA', 'NA', most_frequent,uniq, sum(pd.isnull(vals))])
        else:
            summary_list.append([i, vals.dtype, vals.min(), vals.max(), vals.mean(),vals.nunique(), sum(pd.isnull(vals))])
    return pd.DataFrame(summary_list, columns=['col','dtype','min','max','mean_or_most_common','num_uniq','null_count'])



# Establishing the PostgreSQL connection

# In[4]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Raw FRN Line Items (2016)

# In[5]:

cur.execute("select * from fy2016.frn_line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[6]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Clean Line Items (2016)

# In[7]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[8]:

#raw = pd.read_csv('LocalLargeFiles/fy2016_frn_line_items.csv',low_memory=False)
#clean = pd.read_csv("LocalLargeFiles/fy2016_line_items.csv",low_memory=False)
#metadata = pd.read_csv("LocalLargeFiles/fy2016_frns.csv",low_memory=False)


# -----

# ## Data Setup

# In[8]:

cols = ['frn','funding_request_nickname','service_type','service_provider_name','service_provider_number','narrative',       'total_monthly_recurring_charges','total_monthly_eligible_charges','fiber_type','funding_commitment_request']

## Method Commentd Out Grabs Everything That is Unique
# metadata[cols]
uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
mg_raw = pd.merge(raw, metadata[uniq_cols], on='frn', how='left')

print mg_raw.shape


# ** Assign Broadband True/False - (Adapted from ESH - R Scripts) **

# In[9]:

broadband_types = [
    'Miscellaneous',
    'Cabinets', 
    'Cabling', 
    'Conduit',
    'Connectors/Couplers', 
    'Patch Panels', 
    'Routers', 
    'Switches', 
    'UPS'
]
mg_raw['broadband'] = (mg_raw.service_type == 'Data Transmission and/or Internet Access') & (-mg_raw.function.isin(broadband_types))

full_mg = mg_raw[mg_raw.broadband == True]
print full_mg.shape


# In[ ]:

## merge on frn_complete id:
## take out any frn_complete ids that are duplicated in the clean sample
## these are de-bundled line items and we don't want them in the model sample
## collect duplicate frn_complete ids
df_duplicates = clean.groupby(['frn_complete']).size().reset_index().rename(columns={0:'count_duplicates'})
df_duplicates = df_duplicates[df_duplicates.count_duplicates >= 2]
print df_duplicates.shape

clean = clean[-clean.frn_complete.isin(df_duplicates.frn_complete)]
print clean.shape


# In[ ]:

clean.columns = ['cl_'+c for c in clean.columns]


# In[ ]:

full_mg = pd.merge(full_mg, clean[['cl_id','cl_connect_category','cl_exclude']], left_on='id', right_on='cl_id', how='left')
print full_mg.shape

full_mg = full_mg[(full_mg.cl_exclude == False)]
print full_mg.shape

#print full_mg.shape
#full_mg = pd.merge(full_mg, clean[(clean.cl_exclude == False)][['cl_id','cl_connect_category']], \
#                   left_on='id',right_on='cl_id',how='inner')
#full_mg.shape


# --------

# **Trim to the Broadband Related Rows**

# In[12]:

connect_cat_summary = pd.concat([pd.DataFrame(full_mg['cl_connect_category'].value_counts()),           pd.DataFrame(full_mg['cl_connect_category'].value_counts(normalize=True))],          axis=1)

connect_cat_row_total = pd.DataFrame(full_mg['cl_connect_category'].value_counts()).reset_index()
connect_cat_summary


# ** Drop Uncategorized **

# In[13]:

full_mg = full_mg[full_mg.cl_connect_category != 'Uncategorized']


# -------
# 
# -------

# # Basic Summary

# In[14]:

summary_data = summary(full_mg)


# # Exploration

# ## A. Looking at Narrative Field
# 
# 
# ### A.1 First Just Check If Certain Words are in the Narrative Fields

# In[15]:

narrative_test = full_mg[['frn','type_of_product','purpose','narrative','cl_connect_category']]
narrative_test.is_copy=False
narrative_test.narrative = [str(i) for i in narrative_test.narrative]


# In[16]:

extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']

## TODO - Maybe provide multiple words for each type instead of just a column for each word
def assign_narrative_dummys(df):
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']
    for f in extra_features:
        df['dmy_'+f] = df.narrative.            apply(lambda x: True if f in x.lower().replace('-','') else False)
    return df
narrative_test = assign_narrative_dummys(narrative_test)


# In[17]:

nar_grp = narrative_test.groupby('cl_connect_category').sum().reset_index()


# In[18]:

dmy_totals = nar_grp[['cl_connect_category']+['dmy_'+i for i in extra_features]]
# totals = pd.DataFrame(narrative_test.cl_connect_category.value_counts()).reset_index()
# totals.columns=['cl_connect_category','class_totals']
# pd.merge(dmy_totals, totals,left_on='cl_connect_category',right_on='cl_connect_category')


# ** Review Table**

# In[19]:

dmy_totals


# **Review Heatmap**

# In[20]:

dmy_totals_n = dmy_totals.copy(deep=True)
dmy_totals_n.index = dmy_totals_n.cl_connect_category
dmy_totals_n.drop('cl_connect_category',axis=1,inplace=True)
dmy_totals_n = dmy_totals_n.div(dmy_totals_n.max(axis=1), axis=0)
fig, ax = plt.subplots(figsize=(8,8))         # Sample figsize in inches
sns.heatmap(dmy_totals_n.T)
sns.set(font_scale=1.4)
plt.xticks(rotation=60) 


# -------------

# ### A.2 Use Most Common Words in the Narrative Text of Each Full Group Find Rowise Similarity to each Master Group

# In[21]:

ENGLISH_STOP_WORDS = [
    "a", "about", "above", "across", "after", "afterwards", "again", "against",
    "all", "almost", "alone", "along", "already", "also", "although", "always",
    "am", "among", "amongst", "amoungst", "amount", "an", "and", "another",
    "any", "anyhow", "anyone", "anything", "anyway", "anywhere", "are",
    "around", "as", "at", "back", "be", "became", "because", "become",
    "becomes", "becoming", "been", "before", "beforehand", "behind", "being",
    "below", "beside", "besides", "between", "beyond", "bill", "both",
    "bottom", "but", "by", "call", "can", "cannot", "cant", "co", "con",
    "could", "couldnt", "cry", "de", "describe", "detail", "do", "done",
    "down", "due", "during", "each", "eg", "eight", "either", "eleven", "else",
    "elsewhere", "empty", "enough", "etc", "even", "ever", "every", "everyone",
    "everything", "everywhere", "except", "few", "fifteen", "fifty", "fill",
    "find", "fire", "first", "five", "for", "former", "formerly", "forty",
    "found", "four", "from", "front", "full", "further", "get", "give", "go",
    "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter",
    "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his",
    "how", "however", "hundred", "i", "ie", "if", "in", "inc", "indeed",
    "interest", "into", "is", "it", "its", "itself", "keep", "last", "latter",
    "latterly", "least", "less", "ltd", "made", "many", "may", "me",
    "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly",
    "move", "much", "must", "my", "myself", "name", "namely", "neither",
    "never", "nevertheless", "next", "nine", "no", "nobody", "none", "noone",
    "nor", "not", "nothing", "now", "nowhere", "of", "off", "often", "on",
    "once", "one", "only", "onto", "or", "other", "others", "otherwise", "our",
    "ours", "ourselves", "out", "over", "own", "part", "per", "perhaps",
    "please", "put", "rather", "re", "same", "see", "seem", "seemed",
    "seeming", "seems", "serious", "several", "she", "should", "show", "side",
    "since", "sincere", "six", "sixty", "so", "some", "somehow", "someone",
    "something", "sometime", "sometimes", "somewhere", "still", "such",
    "system", "take", "ten", "than", "that", "the", "their", "them",
    "themselves", "then", "thence", "there", "thereafter", "thereby",
    "therefore", "therein", "thereupon", "these", "they", "thick", "thin",
    "third", "this", "those", "though", "three", "through", "throughout",
    "thru", "thus", "to", "together", "too", "top", "toward", "towards",
    "twelve", "twenty", "two", "un", "under", "until", "up", "upon", "us",
    "very", "via", "was", "we", "well", "were", "what", "whatever", "when",
    "whence", "whenever", "where", "whereafter", "whereas", "whereby",
    "wherein", "whereupon", "wherever", "whether", "which", "while", "whither",
    "who", "whoever", "whole", "whom", "whose", "why", "will", "with",
    "within", "without", "would", "yet", "you", "your", "yours", "yourself",
    "yourselves"]
SYMBOLS = list('{}()[].,:;+-*/&|<>=~$1234567890')

most_common = []
for i in narrative_test.index:
    most_common += narrative_test.ix[i].narrative.lower().split()
DROP_WORDS = [i[0] for i in Counter(most_common).most_common(9)]
DROP_WORDS += ['school','library']
def remove_commons(x_string):
    x_string = [x for x in x_string if x not in DROP_WORDS+ENGLISH_STOP_WORDS]
    return x_string

def clean_narrative_string(nar):
    for symb in SYMBOLS:
        nar = nar.replace(symb,'')
    nar = remove_commons(nar.lower().split())
    return nar

connect_classes = full_mg.cl_connect_category.unique().tolist()

def get_most_common_by_group(connect_classes,df ):
    class_words = {}
    for cl in connect_classes:
        class_list = []
        test_df = df[df.cl_connect_category == cl]
        for i in test_df.index:
            txt = test_df.ix[i].narrative.lower().split()
            txt = remove_commons(txt)
            class_list += txt
        class_commons = Counter(class_list).most_common(5)
        class_words[cl]=class_commons

    return class_words


def counter_cosine_similarity(c1, c2):
    c1 = Counter([x[0] for x in c1])
    c2 = Counter([x[0] for x in c2])

    terms = set(c1).union(c2)
    dotprod = sum(c1.get(k, 0) * c2.get(k, 0) for k in terms)
    magA = math.sqrt(sum(c1.get(k, 0)**2 for k in terms))
    magB = math.sqrt(sum(c2.get(k, 0)**2 for k in terms))
    return dotprod / (magA * magB)

def class_similar_score(cl_words, nar_str):
    nar_str = clean_narrative_string(nar_str)
    if len(nar_str) >0:
        return counter_cosine_similarity(cl_words, nar_str)
    else:
        return -1


class_common_words = get_most_common_by_group(connect_classes, narrative_test)


# ### See the Most Common Words by Labeled Connect Type Group

# In[22]:

class_common_words


# In[23]:

for cl in connect_classes:
    cl_words = [i[0] for i in class_common_words[cl]] 
    label_cl = cl.lower().replace(' ','_').replace('/','_').replace('-','_')
    print label_cl
    narrative_test.loc[:,'mcw_'+label_cl] = narrative_test.narrative.apply(                                                        lambda x: class_similar_score(cl_words, x))


# In[24]:

narrative_test[['narrative','cl_connect_category','mcw_lit_fiber','mcw_dsl','mcw_fixed_wireless','mcw_dark_fiber',               'mcw_t_1','mcw_cable','mcw_not_broadband','mcw_other_copper','mcw_isp_only','mcw_satellite_lte']]


# ### NOTE: Results don't look that great - the simple check of if the word is present in the string appears to work better. Will save the save the code and maybe revisit. 

# -------------
# 
# ------------

# ## B. Looking at the Type of Product Field

# In[25]:

connect_cat_summary


# **Review Table**

# In[26]:

top = pd.DataFrame(full_mg.type_of_product.value_counts()).reset_index()
top.columns = ['type_of_product','top_count']
grp = full_mg[['cl_connect_category','type_of_product']].pivot_table(index='cl_connect_category', columns='type_of_product', aggfunc=len, fill_value=0)
_grp = grp.copy(deep=True)
grp = grp.T.reset_index()
grp = pd.merge(grp, top, on='type_of_product',how='left')

_t = connect_cat_row_total.copy(deep=True).T.reset_index()
_t.columns = [['type_of_product']+_t.ix[0].tolist()[1:]]
grp.append(_t.ix[1])


# **Review Heatmap**

# In[27]:

grp_n = _grp.div(_grp.max(axis=0), axis=1)
fig, ax = plt.subplots(figsize=(13,13))         # Sample figsize in inches
sns.heatmap(grp_n.T)


# ## C. Function Field

# **Review Table**

# In[28]:

full_mg.function.value_counts()
f_grp = full_mg[['cl_connect_category','function']].pivot_table(index='cl_connect_category',                                                                 columns='function', aggfunc=len, fill_value=0)
f_grp


# ## D. Misc

# ### D-1. Postal CD (AKA State Abbrv)

# In[29]:

def esh_pivot(df, idx,cols):
    return df[[idx,cols]].pivot_table(index=idx, columns=cols, aggfunc=len, fill_value=0)


# In[30]:

function_grp = esh_pivot(full_mg,'postal_cd','cl_connect_category')


# **Review Table**

# In[31]:

function_grp


# **Review Heatmap**

# In[32]:

fig, ax = plt.subplots(figsize=(13,23))         # Sample figsize in inches
_ = sns.heatmap(function_grp.div(function_grp.sum(axis=1),axis=0))
plt.yticks(rotation=0)
plt.xticks(rotation=25)
plt.show()


# ### D-2. Purpose
# 
# #### Percent by Group

# In[32]:

purpose_grp = esh_pivot(full_mg,'purpose','cl_connect_category')
purpose_grp.div(purpose_grp.sum(axis=1),axis=0)


# **Notes**: 
# 1. The last category looks useful in spotting the ISP only records. 
# 2. The others are dominated by the Lit Fiber for the most part. 

# ### D-3 Funding Nickname Field

# In[33]:

def assign_nickname_dummys(df):
    df.is_copy = False
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']
    for f in extra_features:
        print "Processing", f
        df.loc[:,'dmy_'+f] = df.funding_request_nickname.            apply(lambda x: True if f in x.lower().replace('-','') else False)
    return df
assign_nickname_dummys(full_mg[['cl_connect_category','narrative','funding_request_nickname']]).sum(axis=0)


# **NOTE**: The nickname field picks up some of the connect category fields - but not much compared to the narrative field. May leave out for now

# ## E. Download and Upload Speeds

# In[34]:

for col in full_mg.columns:
    try:
        full_mg[col] = full_mg[col].astype(float)
    except ValueError:
        continue


# ** Hist of Raw Upload Speed -  Looks like a lot of 0 or low values, plus some very high values. **
# 
# Need to clean and noralize the column.

# In[35]:

sns.distplot(full_mg[full_mg.upload_speed.notnull()].upload_speed)
print full_mg.upload_speed.describe()
print sum(full_mg.upload_speed.isnull())


# ** Hist of Raw Download Speed -  Looks like a lot of 0 or low values, plus some very high values. **
# 

# In[37]:

sns.distplot(full_mg[full_mg.download_speed.notnull()].upload_speed)
print full_mg.download_speed.describe()
print sum(full_mg.download_speed.isnull())


# ** Hist of Just the MBPS Set **

# In[36]:

sns.distplot(full_mg[full_mg.download_speed_units == 'Mbps'].download_speed)


# **Hist of Just the GBPS Set**

# In[37]:

print full_mg[(full_mg.download_speed_units == 'Gbps') & (full_mg.download_speed > 101)].shape


# In[40]:

# sns.distplot(full_mg[full_mg.download_speed_units == 'Gbps'].download_speed,kde=False, rug=True)


# ### Standardize the Speeds

# In[38]:

def std_speed_units(row, unit_col, speed_col):
    if row[speed_col] is not None and not pd.isnull(row[speed_col]):
        if (row[speed_col] > 101) and (row[unit_col] == 'Gbps'):
            print row.id, 'has weird speed values. -- Verify'
            return row[speed_col]
        else:
            return row[speed_col] * {None:1,'Mbps':1, 'Gbps':1000}[row[unit_col]]
    else:
        return None

def normailze_speed(df):
    df = df.copy(deep=True)
    df.upload_speed = df.upload_speed.astype(float)
    df.download_speed = df.download_speed.astype(float)

    df['std_upload_spd'] = df.apply(lambda row: std_speed_units(row,'upload_speed_units','upload_speed'),axis=1)
    df['std_download_spd'] = df.apply(lambda row: std_speed_units(row,'download_speed_units','download_speed'),axis=1)
    return df


# In[39]:

full_mg = normailze_speed(full_mg)


# **Notes**: There is a large range in the upload and download speeds. The speeds also cannot be taken as truth as there is many of these values end up being changed in the "CLEAN" version. If these values were accurate we would likely be able to determine the connection type directly from the speeds - or this would at least be one of the most important features. 
# 
# We could build a model to predict the clean speed but I am guessing the clean speed is a function of the connect category- so we might as well just stick with predicting the connect category. 
# 
# Hopefully the model can pick out those locations where the speed is incorrect for the type - I am not seeing any straight forward way to correct the DL/UL speeds.

# In[40]:

fig, ax = plt.subplots(figsize=(13,8))         # Sample figsize in inches
sns.distplot(np.log10(full_mg[full_mg.std_download_spd.notnull()].std_download_spd))


# In[44]:

fig, ax = plt.subplots(figsize=(13,8))         # Sample figsize in inches
sns.distplot(np.log10(full_mg[full_mg.upload_speed.notnull()].upload_speed))


# ### Review Some of the Averages for Speed and Cost by Connect Category

# In[41]:

full_mg[full_mg.std_download_spd > 0].groupby('cl_connect_category').agg(                                {'monthly_recurring_unit_costs':['min','max','mean','median'],
                                 'std_download_spd':['min','max','mean','median']
                                })


# ------

# 

# In[ ]:




# # END 

# ------
