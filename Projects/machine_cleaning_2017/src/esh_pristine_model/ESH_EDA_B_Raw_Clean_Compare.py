
# coding: utf-8

# ![title](DataKind_orange_small.png)

# ----------

# # TITLE: ESH Raw and Clean Comparison 
# 
# # Summary
# 
# ESH adapted the DK code to review the transformed and flagged 2016 data against the cleaned 2016 data.
# 
# Previous Note by DK: ESH provided both raw and clean version of their 2016 data. In this notebook we will see what changed in some comparable columns in the cleaning process.
# **Main Output**: We will also export a dataset showing the changes. 

# ----

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ---------

# # Import Libraries

# In[6]:

import sys
import os
import psycopg2
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import math
from collections import Counter
import re
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",151)
get_ipython().magic(u'matplotlib inline')


# ## Local Helper Functions

# In[3]:

## correct the number of lines variable: num_lines
## and the service category variable: service_category
## there are values such as "1.0", "1", "Unknown", "NaN" that do not allow for easy conversion to type int
def treat_tough_string_vars(col):
    var_corrected = []
    for row in raw_clean_mg[col]:
        if row != "Unknown":
            try:
                var_corrected.append(int(re.split(r"\.\s*", row)[0]))
            except:
                var_corrected.append(None)
        else:
            var_corrected.append(None)

    raw_clean_mg[col] = var_corrected
    #raw_clean_mg[col] = raw_clean_mg[col].astype(int)
    return raw_clean_mg

## make values integer when there is a NULL value
def make_int(x):
    if pd.isnull(x):
        return None
    else:
        return int(float(x))


# -------

# # Load and Set up the Data 

# Establishing the PostgreSQL connection for PRIS2016

# In[4]:

HOST = os.environ.get("HOST_PRIS2016")
USER = os.environ.get("USER_PRIS2016")
PASSWORD = os.environ.get("PASSWORD_PRIS2016")
DB = os.environ.get("DB_PRIS2016")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# FRN Line Items (2016, Pristine)

# In[5]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[6]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Establishing the PostgreSQL connection for ONYX

# In[7]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Clean Line Items (2016)

# In[8]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[ ]:

#raw = pd.read_csv('../LocalLargeFiles/fy2016_frn_line_items.csv',low_memory=False)
#clean = pd.read_csv("../LocalLargeFiles/fy2016_line_items.csv",low_memory=False)
#metadata = pd.read_csv("../LocalLargeFiles/fy2016_frns.csv",low_memory=False)


# ## Data Setup

# In[9]:

#cols = ['frn','funding_request_nickname','service_type','service_provider_name','service_provider_number','narrative',\
#       'total_monthly_recurring_charges','total_monthly_eligible_charges','fiber_type','funding_commitment_request']

## Method Commentd Out Grabs Everything That is Unique
# metadata[cols]

## merge in columns that don't exist already in metadata
uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
mg_raw = pd.merge(raw, metadata[uniq_cols], on='frn', how='left')
print mg_raw.shape


# **Trim to just Broadband**

# In[10]:

## when using raw USAC data, we had to define broadband, but the pristine dataset already has the indicator

#broadband_types = [
#    'Miscellaneous',
#    'Cabinets', 
#    'Cabling', 
#    'Conduit',
#    'Connectors/Couplers', 
#    'Patch Panels', 
#    'Routers', 
#    'Switches', 
#    'UPS'
#]
#mg_raw['broadband'] = (mg_raw.service_type == 'Data Transmission and/or Internet Access') & \
#    (-mg_raw.function.isin(broadband_types))

## now can subset just to broadband line items
mg_raw = mg_raw[mg_raw.broadband == True]
print mg_raw.shape


# ------
# 

# # Start Comparing the Clean to the Raw

# ## Format Columns

# ** Download Speed and Bandwidth**

# In[12]:

## converting the bandwidth in original units
mg_raw.loc[:,'bandwidth_in_original_units_split'] = mg_raw.bandwidth_in_original_units.apply(lambda x: x.split(' ')[0])
mg_raw.loc[:,'bandwidth_original_units_split'] = mg_raw.bandwidth_in_original_units.apply(lambda x: x.split(' ')[1])

clean.loc[:,'bandwidth_in_original_units_split'] = clean.bandwidth_in_original_units.apply(lambda x: x.split(' ')[0])
clean.loc[:,'bandwidth_original_units_split'] = clean.bandwidth_in_original_units.apply(lambda x: x.split(' ')[1])


# **Total eligble recurring cost and Total Cost**

# In[13]:

mg_raw.total_cost = mg_raw.total_cost.astype(float)
clean.total_cost = clean.total_cost.astype(float)

#mg_raw['total_cost'] = mg_raw.total_eligible_recurring_costs.astype(float)
#mg_raw['connect_type'] = mg_raw.type_of_product
#clean.num_lines = clean.num_lines.astype(int)
#mg_raw.num_lines = mg_raw.num_lines.astype(int)


# **What are the shared columns and how many are there?**

# In[14]:

shared_cols = list(set(mg_raw.columns.tolist()) & set(clean.columns.tolist()))
print len(shared_cols)
shared_cols


# **Add back in Narrative and Connect Category for Reference **

# In[15]:

sh_raw = mg_raw[shared_cols + ['narrative']]
sh_clean = clean[shared_cols]


# **Add a prefix to the raw data columns**

# In[16]:

sh_raw = sh_raw.add_prefix('raw_')


# **Merge the Data**

# In[17]:

## merge on frn_complete id:
## take out any frn_complete ids that are duplicated in the clean sample
## these are de-bundled line items and we don't want them in the model sample
## collect duplicate frn_complete ids
df_duplicates = sh_clean.groupby(['frn_complete']).size().reset_index().rename(columns={0:'count_duplicates'})
df_duplicates = df_duplicates[df_duplicates.count_duplicates >= 2]
print df_duplicates.shape

sh_clean = sh_clean[-sh_clean.frn_complete.isin(df_duplicates.frn_complete)]
print sh_clean.shape


# In[18]:

raw_clean_mg = pd.merge(sh_raw, sh_clean, left_on='raw_frn_complete', right_on='frn_complete', how='left')


# **Subset to only where Exclude = FALSE **

# In[19]:

raw_clean_mg = raw_clean_mg[(raw_clean_mg.exclude == False)]
print raw_clean_mg.shape


# ***Clean Up Download Speeds (known as bandwidth_in_mbps now)***

# In[20]:

## "Convert to integer to correct for decimal differences 1.54-> 1.5 to just 1 and 1"
raw_clean_mg.loc[:,'raw_bandwidth_in_mbps'] = raw_clean_mg.raw_bandwidth_in_mbps.apply(make_int)
raw_clean_mg.loc[:,'bandwidth_in_mbps'] = raw_clean_mg.bandwidth_in_mbps.apply(make_int)

raw_clean_mg.loc[:,'raw_bandwidth_in_original_units_split'] = raw_clean_mg.raw_bandwidth_in_original_units_split.apply(make_int)
raw_clean_mg.loc[:,'bandwidth_in_original_units_split'] = raw_clean_mg.bandwidth_in_original_units_split.apply(make_int)


# **Format Other Columns**

# In[21]:

## turn application number and FRN to strings
raw_clean_mg.application_number = raw_clean_mg.application_number.astype(str)
raw_clean_mg.raw_application_number = raw_clean_mg.raw_application_number.astype(str)
raw_clean_mg.frn = raw_clean_mg.frn.astype(str)
raw_clean_mg.raw_frn = raw_clean_mg.raw_frn.astype(str)


# In[22]:

## treat the number of lines variable ("1" vs "1.0")
raw_clean_mg = treat_tough_string_vars("num_lines")
raw_clean_mg = treat_tough_string_vars("raw_num_lines")


# In[23]:

## treat the service category variable ("1" vs "1.0")
raw_clean_mg = treat_tough_string_vars("service_category")
raw_clean_mg.loc[:,'raw_service_category'] = raw_clean_mg.raw_service_category.apply(make_int)


# In[24]:

## fill the remaining NA values with -1
raw_clean_mg.fillna(-1,inplace=True)


# **See Current Comparision**

# Shows the percent that has changed by each of the shared columns. 

# In[25]:

## I get the same percentages in R.
## Most of the differences come from NA's in either version.
## I did a version in R that ignores NA fields and the following variables are the only ones with differences above 10%:
## "id", "open_tag_labels", "num_open_flags" "open_flag_labels", "upload_bandwidth_in_mbps".
## (the first 4 make sense because those define why a district would be dirty)

for col in shared_cols:
    total_changed = sum(raw_clean_mg['raw_'+col] != raw_clean_mg[col])
    print col, total_changed, round((total_changed/(len(raw_clean_mg)*1.0))*100,0),'%'


# ----

# # Examine Some Specific Columns

# Dig in a little deeper on some of the columns

# **Compare Function**

# In[26]:

def compare_cols(df,col):
    return pd.concat([df[['raw_'+col,col]],          pd.DataFrame(df['raw_'+col] == df[col])], axis=1)


# ----

# ### Function Review (don't have to do this anymore)

# In[44]:

function_compare = compare_cols(raw_clean_mg,'function')


# Combine the Raw Value and Clean Value into a single column so we can see group counts

# In[45]:

function_compare.loc[:,'ba_function'] = function_compare.apply(lambda row:                                     row.raw_function + '_' + row.function, axis=1)

#function_compare.loc[:,'function'] = function_compare.apply(lambda row: \
#                                    row.raw_function + '_' + row.function, axis=1)


# ** Function Options **

# In[46]:

function_compare.ba_function.value_counts()


# In[47]:

function_compare.shape


# In[48]:

function_compare[function_compare[0]==False].ba_function.value_counts()


# What are all these Fiber -> Voice .... = Not Broadband

# In[ ]:

#raw_clean_mg[(raw_clean_mg.function == 'Voice') & (raw_clean_mg.raw_function == 'Fiber')].connect_category.value_counts()


# ----

# ### Speed Compare

# In[ ]:

#speed_compare = pd.concat([raw_clean_mg[['raw_download_speed','download_speed','raw_download_speed_units','download_speed_units']],\
#          pd.DataFrame(raw_clean_mg.raw_download_speed == raw_clean_mg.download_speed)], axis=1)


# In[27]:

speed_compare = pd.concat([raw_clean_mg[['raw_bandwidth_in_mbps','bandwidth_in_mbps', 'raw_bandwidth_in_original_units_split', 'bandwidth_in_original_units_split']],          pd.DataFrame(raw_clean_mg.raw_bandwidth_in_mbps == raw_clean_mg.bandwidth_in_mbps)], axis=1)


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

# In[ ]:

#raw_clean_mg.raw_download_speed = raw_clean_mg.raw_download_speed.astype(int)
#raw_clean_mg.download_speed = raw_clean_mg.download_speed.astype(int)


# ** Selecting Subset of the Shared Cols **

# In[36]:

shared_cols


# **We will select a subset of the shared columns to record whether there was a change or not**
# 
# I'm selecting the subset based on intuition and the presence of multipe values that were changed. I'm only using download speed (and units) since that is what translates to the bandwidth. The service_type is very imbalanced in terms of being changed and generally is only equal to "Data Transmission and/or Internet Access" so skipping that one (but you could include if you think it is important). Skipping months of service because it seems doubtful it will impact the connect category greatly. Skipping the applicition identifiers because they are broadly unique and likely don't impact the connect category greatly. Skipping service provider name because I don't know enough about why that might be changed. 
# 
# 
# In summary - I made some decisions about which columns to keep - and ESH may want to test some others if they have a good reason to do so. 

# **Create Change Columns**

# In[49]:

review_cols = ['function','bandwidth_in_mbps','total_cost','connect_type','purpose']
for c in review_cols:
    if 'diff_'+c in raw_clean_mg.columns:
        del raw_clean_mg['diff_'+c]
    if c == 'bandwidth_in_mbps':
        d = abs(raw_clean_mg['raw_'+c] - raw_clean_mg[c])
        raw_clean_mg.loc[ d < 1,'diff_'+c] = False
    else:
        raw_clean_mg.loc[raw_clean_mg['raw_'+c] == raw_clean_mg[c],'diff_'+c] = False
        
    raw_clean_mg['diff_'+c].fillna(True,inplace=True)
    print c, sum(raw_clean_mg['diff_'+c])


# ** Create a Feature That Has Count of Changes in those Selected Columns (See above)**

# In[50]:

raw_clean_mg.loc[:,'total_changed'] = raw_clean_mg[['diff_'+i for i in review_cols]].sum(axis=1)


# Distribution of counts

# In[51]:

raw_clean_mg.total_changed.value_counts()


# **Review Change Percentages by the Connect Category**

# In[52]:

over = raw_clean_mg[raw_clean_mg.total_changed > 0].connect_category.value_counts()
over =  over /over.sum()
atzero = raw_clean_mg[raw_clean_mg.total_changed == 0].connect_category.value_counts()
atzero = atzero/atzero.sum()
df = pd.concat([atzero,over],axis=1)
df.columns = ['not changed', 'changed']


# Mostly in the Lit Fiber Category

# In[53]:

df


# -------

# # Export Change Data

# In[55]:

raw_clean_mg.to_csv('../../data/interim/changecount_June12_17.csv', encoding='utf-8')


# -------

# **Convert this notebook to a python file**

# In[5]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_EDA_B_Raw_Clean_Compare.ipynb', 'ESH_EDA_B_Raw_Clean_Compare.py', main)


# # END

# --------
