
# coding: utf-8

# ![title](DataKind_orange_small.png)

# ----------

# # TITLE: ESH Raw and Clean Comparison 
# 
# # Summary
# 
# ESH provided both raw and clean version of their data. In this notebook we will see what changed in some comparable columns in the cleaning process.
# **Main Output**: We will also export a dataset showing the changes. 

# ----

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ---------

# # Import Libraries

# In[2]:

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


# -------

# # Load and Set up the Data 

# Establishing the PostgreSQL connection

# In[3]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Raw FRN Line Items (2016)

# In[4]:

cur.execute("select * from fy2016.frn_line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[5]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Clean Line Items (2016)

# In[6]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[12]:

#raw = pd.read_csv('../LocalLargeFiles/fy2016_frn_line_items.csv',low_memory=False)
#clean = pd.read_csv("../LocalLargeFiles/fy2016_line_items.csv",low_memory=False)
#metadata = pd.read_csv("../LocalLargeFiles/fy2016_frns.csv",low_memory=False)


# In[7]:

cols = ['frn','funding_request_nickname','service_type','service_provider_name','service_provider_number','narrative',       'total_monthly_recurring_charges','total_monthly_eligible_charges','fiber_type','funding_commitment_request']

## Method Commentd Out Grabs Everything THat is Unique
# metadata[cols]
uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
mg_raw = pd.merge(raw, metadata[uniq_cols], on='frn',how='left')

print mg_raw.shape


# **Trim to just Broadband**

# In[8]:

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
mg_raw['broadband'] = (mg_raw.service_type == 'Data Transmission and/or Internet Access') &     (-mg_raw.function.isin(broadband_types))
mg_raw = mg_raw[mg_raw.broadband == True]
print mg_raw.shape


# **Clean Exclude**

# In[9]:

clean = clean[(clean.exclude == False)]
print clean.shape


# ------
# 

# # Start Comparing the Clean to the Raw

# In[10]:

print mg_raw.shape
print clean.shape


# ## Relabel Columns so they Match

# ** Download Speed and Bandwidth**

# In[11]:

clean.loc[:,'download_speed'] = clean.bandwidth_in_original_units.apply(lambda x: x.split(' ')[0])
clean.loc[:,'download_speed_units'] = clean.bandwidth_in_original_units.apply(lambda x: x.split(' ')[1])


# **Total eligble recurring cost and Total Cost**

# In[12]:

mg_raw['total_cost'] = mg_raw.total_eligible_recurring_costs.astype(float)
mg_raw['connect_type'] = mg_raw.type_of_product
clean.total_cost = clean.total_cost.astype(float)


# -----

# ## What are the shared columns and how many are there?

# In[13]:

shared_cols = list(set(mg_raw.columns.tolist()) & set(clean.columns.tolist()))
print len(shared_cols)
shared_cols


# **Add back in Narrative and Connect Category for Reference **

# In[14]:

sh_raw = mg_raw[shared_cols + ['narrative']]
sh_clean = clean[shared_cols + ['connect_category']]


# **Add a prefix to the raw data columns**

# In[15]:

sh_raw = sh_raw.add_prefix('raw_')


# **Merge the Data**

# In[16]:

raw_clean_mg = pd.merge(sh_raw, sh_clean, left_on = 'raw_id', right_on = 'id', how='inner')


# In[17]:

raw_clean_mg.shape


# ** Clean Up Download Speeds**

# In[18]:

def make_int(x):
    "Convert to integer to correct for decimal differences 1.54-> 1.5 to just 1 and 1"
    if pd.isnull(x):
        return None
    else:
        return int(float(x))
raw_clean_mg.loc[:,'raw_download_speed'] = raw_clean_mg.raw_download_speed.apply(make_int)
raw_clean_mg.loc[:,'download_speed'] = raw_clean_mg.download_speed.apply(make_int)


# **See Current Comparision**

# Shows the percent that has changed by each of the shared columns. 

# In[19]:

raw_clean_mg.application_number = raw_clean_mg.application_number.astype(str)
raw_clean_mg.raw_application_number = raw_clean_mg.raw_application_number.astype(str)
raw_clean_mg.frn = raw_clean_mg.frn.astype(str)
raw_clean_mg.raw_frn = raw_clean_mg.raw_frn.astype(str)

raw_clean_mg.fillna(-1,inplace=True)
for col in shared_cols:
    total_changed = sum(raw_clean_mg['raw_'+col] == raw_clean_mg[col])
    print col, total_changed, total_changed/(len(raw_clean_mg)*1.0),'%'


# ----

# # Examine Some Specific Columns

# Dig in a little deeper on some of the columns

# **Compare Function**

# In[20]:

def compare_cols(df,col):
    return pd.concat([df[['raw_'+col,col]],          pd.DataFrame(df['raw_'+col] == df[col])], axis=1)


# ----

# ### Function Review

# In[21]:

function_compare = compare_cols(raw_clean_mg,'function')


# Combine the Raw Value and Clean Value into a single column so we can see group counts

# In[22]:

function_compare.loc[:,'ba_function'] = function_compare.apply(lambda row:                                     row.raw_function + '_' + row.function, axis=1)


# ** Function Options **

# In[23]:

function_compare.raw_function.value_counts()


# In[24]:

function_compare.shape


# In[25]:

function_compare[function_compare[0]==False].ba_function.value_counts()


# What are all these Fiber -> Voice .... = Not Broadband

# In[26]:

raw_clean_mg[(raw_clean_mg.function == 'Voice') & (raw_clean_mg.raw_function == 'Fiber')].connect_category.value_counts()


# ----

# ### Speed Compare

# In[27]:

speed_compare = pd.concat([raw_clean_mg[['raw_download_speed','download_speed','raw_download_speed_units','download_speed_units']],          pd.DataFrame(raw_clean_mg.raw_download_speed == raw_clean_mg.download_speed)], axis=1)


# In[28]:

speed_compare[speed_compare[0] == False]


# ------

# ### Purpose Compare

# In[29]:

purpose_compare = compare_cols(raw_clean_mg,'purpose')


# In[30]:

purpose_compare[purpose_compare[0]==False]


# -------

# ### Cost Compare

# In[31]:

cost_compare = compare_cols(raw_clean_mg,'total_cost')


# In[32]:

cost_compare['cdif'] = cost_compare.total_cost - cost_compare.raw_total_cost


# In[33]:

## Divided by 100000 
g = sns.distplot(((cost_compare[(cost_compare[0]==False)].cdif.astype(int))/100000))
g.figure.set_size_inches(16,6)


# In[34]:

cost_compare[(cost_compare.cdif > 1000) | (cost_compare.cdif < -1000)].shape


# In[35]:

cost_compare[cost_compare[0]==False]


# -------

# # Count the Number of Changes 

# In[36]:

raw_clean_mg.raw_download_speed = raw_clean_mg.raw_download_speed.astype(int)
raw_clean_mg.download_speed = raw_clean_mg.download_speed.astype(int)


# ** Selecting Subset of the Shared Cols **

# In[37]:

shared_cols


# **We will select a subset of the shared columns to record whether there was a change or not**
# 
# I'm selecting the subset based on intuition and the presence of multipe values that were changed. I'm only using download speed (and units) since that is what translates to the bandwidth. The service_type is very imbalanced in terms of being changed and generally is only equal to "Data Transmission and/or Internet Access" so skipping that one (but you could include if you think it is important). Skipping months of service because it seems doubtful it will impact the connect category greatly. Skipping the applicition identifiers because they are broadly unique and likely don't impact the connect category greatly. Skipping service provider name because I don't know enough about why that might be changed. 
# 
# 
# In summary - I made some decisions about which columns to keep - and ESH may want to test some others if they have a good reason to do so. 

# **Create Change Columns**

# In[38]:

review_cols = ['function','download_speed_units','total_cost','application_number',
               'connect_type','purpose','download_speed']
for c in review_cols:
    if 'diff_'+c in raw_clean_mg.columns:
        del raw_clean_mg['diff_'+c]
    if c == 'download_speed':
        d = abs(raw_clean_mg['raw_'+c] - raw_clean_mg[c])
        raw_clean_mg.loc[ d< 1,'diff_'+c] = False
    else:
        raw_clean_mg.loc[raw_clean_mg['raw_'+c] == raw_clean_mg[c],'diff_'+c] = False
        
    raw_clean_mg['diff_'+c].fillna(True,inplace=True)
    print c, sum(raw_clean_mg['diff_'+c])


# ** Create a Feature That Has Count of Changes in those Selected Columns (See above)**

# In[39]:

raw_clean_mg.loc[:,'total_changed'] = raw_clean_mg[['diff_'+i for i in review_cols]].sum(axis=1)


# Distribution of counts

# In[40]:

raw_clean_mg.total_changed.value_counts()


# **Review Change Percentages by the Connect Category**

# In[41]:

over = raw_clean_mg[raw_clean_mg.total_changed > 0].connect_category.value_counts()
over =  over /over.sum()
atzero = raw_clean_mg[raw_clean_mg.total_changed == 0].connect_category.value_counts()
atzero = atzero/atzero.sum()
df = pd.concat([atzero,over],axis=1)
df.columns = ['not changed', 'changed']


# Mostly in the Lit Fiber Category

# In[42]:

df


# -------

# # Export Change Data

# In[44]:

raw_clean_mg.to_csv('model_data_versions/changecount_June16_17.csv', encoding='utf-8')


# -------

# # END

# --------
