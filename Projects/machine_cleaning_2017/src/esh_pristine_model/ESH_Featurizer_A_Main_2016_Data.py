
# coding: utf-8

# ---------

# ![title](DataKind_orange_small.png)
# 

# ------------

# # TITLE: ESH 2016 Data Featurizer 

# # Summary
# In this notebook we will take the 2016 data and clean and process it into a file that can be used in the modeling scripts. 
# 
# Primary cleaning activities:
# * Creating new features
# * Creating dummy variables for categorical features
# * Removing features that are *heavily* null
# * Removing categorical features that have too many values (hundreds to thousands)
# 

# -------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# -------

# # Import Libraries and Data 

# In[1]:

import sys
import os
import psycopg2
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import math
import pickle
from collections import Counter
import re
from decimal import *
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",151)
get_ipython().magic(u'matplotlib inline')


# ------

# # Load 2016 Data

# Establishing the PostgreSQL connection for PRIS2016

# In[3]:

HOST = os.environ.get("HOST_PRIS2016")
USER = os.environ.get("USER_PRIS2016")
PASSWORD = os.environ.get("PASSWORD_PRIS2016")
DB = os.environ.get("DB_PRIS2016")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# FRN Line Items (2016, Pristine)

# In[4]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# Tags for Line Items (2016, Pristine) Can't use right now because we don't have them for 2017

# In[5]:

cur.execute("select count(*) from fy2016.tags where taggable_type = 'LineItem' and deleted_at is Null")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw.tags = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[6]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Service Providers (2016)

# In[7]:

cur.execute("select name, reporting_name from fy2016.service_providers where reporting_name is not NULL")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
service_providers_2016 = pd.DataFrame(rows, columns=names)
service_providers_2016.columns = ['service_provider_name', 'reporting_name']
service_providers_2016.head()


# Establishing the PostgreSQL connection for ONYX

# In[8]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Clean Line Items (2016)

# In[9]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[10]:

#raw = pd.read_csv('LocalLargeFiles/fy2016_frn_line_items.csv',low_memory=False)
#clean = pd.read_csv("LocalLargeFiles/fy2016_line_items.csv",low_memory=False)
#metadata = pd.read_csv("LocalLargeFiles/fy2016_frns.csv",low_memory=False)

## Service Providers Clean
#service_providers_2016 = pd.read_csv('local_data/service_providers_2016.csv')
#service_providers_2016.head()


# ------

# # Local Helper Functions 

# In[11]:

def summary(df):
    """Takes a DataFrame and creates a summary, does different things if object or numeric features.  """
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
            summary_list.append([i,
                                 vals.dtype, 
                                 'NA', 
                                 'NA', 
                                 most_frequent,
                                 uniq, 
                                 sum(pd.isnull(vals)),
                                 sum(pd.isnull(vals))/(1.0*len(df))])
        else:
            summary_list.append([i,
                                 vals.dtype, 
                                 vals.min(), 
                                 vals.max(), 
                                 vals.mean(),
                                 vals.nunique(), 
                                 sum(pd.isnull(vals)),
                                 sum(pd.isnull(vals))/(1.0*len(df))])
    return pd.DataFrame(summary_list, columns=['col','datatype','min','max','mean_or_most_common','num_uniq','null_count','null_pct'])

    
def color_obeject(val):
    """
    Color the "Object" rows in red - just to help in looking at those fields
    """
    color = 'red' if val == 'O' else 'black'
    return 'color: %s' % color

def color_code_summary(df):
    """Then apply the color to the DateFrame"""
    s = summary(df)
    style_s = s.style.applymap(color_obeject)
    return s, style_s

## make values integer when there is a NULL value
def make_int(x):
    if pd.isnull(x):
        return None
    else:
        return int(float(x))

## correct the number of lines variable: num_lines
## and the service category variable: service_category
## there are values such as "1.0", "1", "Unknown", "NaN" that do not allow for easy conversion to type int
def treat_tough_string_vars(col):
    var_corrected = []
    for row in full_mg[col]:
        if row != "Unknown":
            try:
                var_corrected.append(int(re.split(r"\.\s*", row)[0]))
            except:
                var_corrected.append(None)
        else:
            var_corrected.append(None)

    full_mg[col] = var_corrected
    return full_mg


# -------

# # Data Merging
# 

# Find the unique columns in the metadata table and merge them with the raw table. 

# In[12]:

uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
full_mg = pd.merge(raw, metadata[uniq_cols], on='frn', how='left').copy(deep=True)
print full_mg.shape


# ** Limit to Broadband Type **

# In[13]:

#broadband_types = [
#    'Miscellaneous',
#    'Cabinets', 
#    'Cabling', 
#    'Conduit',
#    'Connectors/Couplers', 
#    'Patch Panels', 
#    'Routers', 
#    'Switches', 
#    'UPS']
#full_mg['broadband'] = (full_mg.service_type == 'Data Transmission and/or Internet Access') \
#    & (-full_mg.function.isin(broadband_types))

## now can subset just to broadband line items
full_mg = full_mg[full_mg.broadband == True]
full_mg.shape


# ** Merge the Clean Cl_Connect_Category Column to the Raw+Metadata Table**

# In[14]:

## merge on frn_complete id:
## take out any frn_complete ids that are duplicated in the clean sample
## these are de-bundled line items and we don't want them in the model sample
## collect duplicate frn_complete ids
df_duplicates = clean.groupby(['frn_complete']).size().reset_index().rename(columns={0:'count_duplicates'})
df_duplicates = df_duplicates[df_duplicates.count_duplicates >= 2]
print df_duplicates.shape

clean = clean[-clean.frn_complete.isin(df_duplicates.frn_complete)]
print clean.shape


# Attach a "cl_" to all the clean columns

# In[15]:

clean.columns = ['cl_'+c for c in clean.columns]


# In[16]:

full_mg = pd.merge(full_mg, clean[['cl_frn_complete','cl_connect_category','cl_exclude']], left_on='frn_complete', right_on='cl_frn_complete', how='left')
full_mg.shape


# In[17]:

full_mg = full_mg[(full_mg.cl_exclude == False)]
print full_mg.shape


# **Attach Cleaned Service Providers**

# In[18]:

full_mg = full_mg.merge(service_providers_2016, on='service_provider_name', how='left')
print full_mg.shape


# **Review Summary**

# In[19]:

connect_cat_summary = pd.concat([pd.DataFrame(full_mg['cl_connect_category'].value_counts()),           pd.DataFrame(full_mg['cl_connect_category'].value_counts(normalize=True))],          axis=1)

connect_cat_row_total = pd.DataFrame(full_mg['cl_connect_category'].value_counts()).reset_index()
connect_cat_summary.columns = ['Count','Percent']
connect_cat_summary


# Cutting - Remove  "Uncategorized" as an Option Since There are Too Few Observations

# In[20]:

full_mg = full_mg[full_mg.cl_connect_category != 'Uncategorized']


# --------

# # Cleaning & Some Feature Creation 
# 
# The order of cleaning/cutting/feature creations is somewhat mixed because we are using some of the cutting to decide which fields to clean, etc. <br>  Ideally we would separate them into separate sequences of code logic - but this is ok. 

# ---------

# # Format Columns

# Treat Certain Columns Separately

# In[21]:

## turn FRN Complete, FRN, and application number to strings
#full_mg.frn_complete = full_mg.frn_complete.astype(str)
#full_mg.frn = full_mg.frn.astype(str)
#full_mg.application_number = full_mg.application_number.astype(str)
## force service_category to INT
full_mg.loc[:,'service_category'] = full_mg.service_category.apply(make_int)
## force bandwidth_in_mbps to INT
full_mg.loc[:,'bandwidth_in_mbps'] = full_mg.bandwidth_in_mbps.apply(make_int)
## force upload_bandwidth_in_mbps to INT
full_mg.loc[:,'upload_bandwidth_in_mbps'] = full_mg.upload_bandwidth_in_mbps.apply(make_int)
## treat the number of lines variable ("1" vs "1.0")
full_mg = treat_tough_string_vars("num_lines")


# Convert Cols to Float

# In[22]:

## Skip it if we can't convert to Float or if we already treated it
cols_already_converted = ['service_category', 'bandwidth_in_mbps', 'upload_bandwidth_in_mbps', 'num_lines',                          'open_flag_labels', 'open_tag_labels', 'frn_complete']
for col in full_mg.columns:
    print col 
    if col not in cols_already_converted:
        try:
            full_mg[col] = full_mg[col].astype(float)
        except (ValueError, TypeError):
            print "ERROR"
            continue


# **Review Summary**

# In[23]:

s1 = summary(full_mg)
s1.sort_values('col')


# --------

# # Cutting Features : Keep Fields less than 15% Null.

# In[24]:

mostly_not_null_cols = s1[s1.null_pct < .15]
model_data = full_mg[mostly_not_null_cols.col.tolist()]
model_data.shape


# ** Review Summary ** 

# In[25]:

s2 = summary(model_data)
s = s2.style.applymap(color_obeject)
s


# ---------

# # Cleaning:  Fill Some of the NA's

# ** We will Record Where We Fill an NA - Just so we know**

# In[26]:

## which columns still have a null percentage > 0
null_cols = s2[s2.null_pct > 0]
null_cols.col.tolist()


# In[27]:

model_data.is_copy = False ## Some silly Pandas thing here - to supress some of the warnings (not super important)
model_data.loc[:,'has_na_fill'] = False  ## Initialize the field 


# In[28]:

model_data.shape


# In[29]:

model_data.dropna().shape


# ## NA Strategy
# Being really intentional here about how we will fill values as some of these are very important in the estimation. Mostly just setting to "UNKNOWN" if the field is null. 

# ** No NAs in new data for all following variables **

# **Type of Product Fill**

# In[30]:

#model_data.loc[model_data.type_of_product.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.type_of_product.isnull(),'type_of_product'] = 'UNKNOWN'


# **Purpose**

# In[31]:

#model_data.loc[model_data.purpose.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.purpose.isnull(),'purpose'] = 'UNKNOWN'


# **Upload and Download Speed**

# In[32]:

#model_data.loc[model_data.download_speed.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.upload_speed.isnull(),'has_na_fill'] = True

#model_data.loc[model_data.download_speed.isnull(),'download_speed'] = -9999
#model_data.loc[model_data.upload_speed.isnull(),'upload_speed'] = -9999


# **Connection Used By**

# In[33]:

#model_data.loc[model_data.connection_used_by.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.connection_used_by.isnull(),'connection_used_by'] = "UNKNOWN"


# **Review Summary**

# In[34]:

sNA = summary(model_data)
s = sNA.style.applymap(color_obeject)
s


# -----

# # Feature Creation - Open Flags and Tags

# ** Need to Break out the Open Flags Columns **

# We will iterate over the "open_flags" list and add a dummy column with a 1 or 0 if the flag is in the open_flag_labels field. (Since the open_flag_labels is empty for every row, we don't treat it.)

# In[35]:

def assign_flag_dummys(df):
    open_flags = ['unknown_conn_type','unknown_quantity','product_bandwidth',                  'not_upstream', 'not_isp','not_bundled_ia','not_wan',                  'fiber_maintenance','flipped_speed','special_construction','not_broadband']
    for flag in open_flags:
        df.loc[:,'flag_'+flag] = df.open_flag_labels.        apply(lambda x: True if flag in x else False)
    return df


# In[36]:

## apply definition above
model_data = assign_flag_dummys(model_data)


# # Feature Creation - Narrative Dummy Creation

# ** First Add the Narrative Dummies **
# 
# We will iterate over the "extra_features" list and add a dummy column with a 1 or 0 if the word/phrase is present in the narrative field. You can add new words or phrases or delete the current ones by editing that list. 

# In[37]:

def assign_narrative_dummys(df):
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper',                      'wan','t3','t1','wireless','microwave']
    for f in extra_features:
        df.loc[:,'dmy_'+f] = df.narrative.            apply(lambda x: True if f in str(x).lower().replace('-','') else False)
    return df

model_data = assign_narrative_dummys(model_data)


# In[38]:

print model_data.shape
#model_data.iloc[:,-14:].head()


# ------

# # Cutting: Remove Columns Singular Columns and those with more than 100 Unique Values

# In[39]:

## List of columns with more than 100 uniqvals (this also takes care of the\
## open_flag_labels, open_tag_labels, and the narrative field)
broadly_unique = sNA[(sNA.datatype == 'O') & (sNA.num_uniq > 100)].col.tolist()
print broadly_unique 
## list of singular columns
singular_cols = sNA[sNA.num_uniq == 1].col.tolist()
print singular_cols
## Remove Reporting Name from the list since we are going to do some work with it
broadly_unique.remove('reporting_name')
## also remove frn_complete id
broadly_unique.remove('frn_complete')
model_data.drop(broadly_unique+singular_cols, axis=1, inplace=True)
model_data.shape


# **Review Summary**

# In[40]:

s3 = summary(model_data)
s3 = s3.style.applymap(color_obeject)
s3


# --------

# # Cutting:  Remove ID Fields
# 
# We can now cut the extra ID fields, or fields that represent unique id numbers. If we include these in the model it can "overfit" easily and just learn the value based on the unique, or semi-unique numbers. 

# ## Mark Id Columns

# In[41]:

## keep frn_complete to be able to take samples for validation later
id_cols = ['id', 'frn', 'cl_frn_complete', 'application_number', 'applicant_ben']


# In[42]:

## Execute the drop
model_data.drop(id_cols, axis=1, inplace=True)


# -------

# ## Export the Current Columns 
# 
# We need these so we can format later year data. We will need 2 lists to format future year data. 
# 
# 1. **List One** (This List) This list will have the primary columns (i.e. not a ton of dummy columns, though we do have the narrative dummies in here), and all the numeric fields we are keeping. 
# 2. **List Two** (Exported Later) This will have all fields including all dummies generated on the 2016 data. We will use that list to verify that the final structure in the future data matches the final structure in the 2016 data. 

# In[43]:

model_columns = model_data.columns.tolist()
#model_columns.remove('has_na_fill')

## also remove columns that we know are not in 2017 data
model_columns.remove('cl_connect_category')
model_columns.remove('applicant_postal_cd')
model_columns.remove('application_type')
model_columns.remove('num_recipients')

with open('model_versions/modeling_columns.pkl','w') as f:
    pickle.dump(model_columns,f)

len(model_columns)


# ------

# # Feature Creation: Standardize DL/UL Speeds 

# In[44]:

#def std_speed_units(row, unit_col, speed_col):
#    """Standardize the speed units, basicaaly if the speed col is not null, we check if the 
#    speed col and the unit col make sense (if GBPS is it less than 101), if so we convert to mbps
#    other wise we assumt that it is mpbs already. """
#    if row[speed_col] is not None and not pd.isnull(row[speed_col]):
#        if (row[speed_col] > 101) and (row[unit_col] == 'Gbps'):
#            print row.id, 'has weird speed values. -- Verify'
#            return row[speed_col]
#        else:
#            return row[speed_col] * {np.nan:1, None:1,'Mbps':1, 'Gbps':1000}[row[unit_col]] ## Picks 1 or 1000 based on the unit
#    else:
#        return None

#def normailze_speed(df):
#    """Fucntion to Execute whole process on a df
#    we apply the std_speed_units() function to the DL and UL data"""
#    df = df.copy(deep=True)
#    df.upload_speed = df.upload_speed.astype(float)
#    df.download_speed = df.download_speed.astype(float)
#    df['std_upload_spd'] = df.apply(lambda row: std_speed_units(row,'upload_speed_units','upload_speed'),axis=1)
#    df['std_download_spd'] = df.apply(lambda row: std_speed_units(row,'download_speed_units','download_speed'),axis=1)
#    return df


# ** Execute the Normalization -- Don't Need to Anymore **

# In[45]:

#model_data = normailze_speed(model_data)


# ------

# # Feature Creation - "Major" Service Provider Dummies

# In[46]:

major_service_provider = model_data.reporting_name.value_counts()


# ** Select only Those Service Providers that had 150+ Values **

# In[47]:

major_service_provider = major_service_provider[major_service_provider >= 150]
major_service_provider = major_service_provider.index.tolist()


# In[48]:

len(major_service_provider)


# **Assign the Dummies**

# In[49]:

for service_provider in major_service_provider:
    model_data.loc[model_data.reporting_name == service_provider,'dmy_'+service_provider] = True
    model_data['dmy_'+service_provider].fillna(False,inplace=True)


# **Delete the Reporting Name and Service Provider Number**

# In[50]:

del model_data['reporting_name']
del model_data['service_provider_number']
del model_data['service_provider_id']


# ---------

# # Feature Creation - Make Categorical Dummies

# **Create a new dataframe - just helps if we want to expiriment with the dummies - don't have to run the whole script** 

# In[51]:

model_data_wdummies = model_data
#model_columns


# ## Multiclass Dummies

# We will assign what the top service providers are in this dataset - but later will limit it to what matches the 2016 data.

# ### Purpose

# Purpose has really long values - so i have created a key to translate them to something shorter (`translate_purpose` list below).
# 
# Simplify the purpose labels and then assign dummies
# 
# **Note** : Use of the prefix argument in `pd.get_dummies() ` that is how we differentiate the different dummy columns.

# **WARNING** -- Watch the Encoding When Dealing With New Data - Verify it is UTF-8 and that you aren't getting null values out of the map because of weird text encoding stuff. 

# In[52]:

translate_purpose = dict(zip([
       'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider',
       'Data Connection between two or more sites entirely within the applicant\xe2\x80\x99s network',
       'Data connection(s) for an applicant\xe2\x80\x99s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately',
       'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)',
       'Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities',
       'UNKNOWN'],['ias_includes_connection','data_connect_2ormore','data_connect_hub','ias_no_circuit','backbone','UNKNOWN']))

## Translate the Purpose to the short values using the map method
model_data_wdummies.purpose = model_data_wdummies.purpose.map(translate_purpose)


# In[53]:

model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.purpose,prefix='purp')],axis=1)
model_data_wdummies.drop('purpose',axis=1,inplace=True)


# ### Function

# Like purpose we will translate the function values using a dictionary.

# In[54]:

model_data.function.unique().tolist()


# In[55]:

function_dict = dict(zip([u'Fiber', u'Copper', u'Fiber Maintenance & Operations', u'Wireless', u'Other'],                             ['fiber','copper','fiber_mat_ops','wireless','other']))
model_data_wdummies.function = model_data_wdummies.function.map(function_dict)
## Attach
model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.function,prefix='fnct')],axis=1)
model_data_wdummies.drop('function',axis=1,inplace=True)


# ### Application Type (not in 2017 Data so have to take this out)

# In[56]:

#model_data_wdummies = pd.concat([model_data_wdummies, \
#                                 pd.get_dummies(model_data_wdummies.application_type,prefix='apptyp')],axis=1)
#model_data_wdummies.drop('application_type',axis=1,inplace=True)
#model_data_wdummies.shape


# ### Connect Type

# In[57]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connect_type,prefix='conntyp')],axis=1)
model_data_wdummies.drop('connect_type',axis=1,inplace=True)
model_data_wdummies.shape


# ### Connect Category

# In[58]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connect_category,prefix='conncat')],axis=1)
model_data_wdummies.drop('connect_category',axis=1,inplace=True)
model_data_wdummies.shape


# ### States

# In[59]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.postal_cd,prefix='st')],axis=1)
model_data_wdummies.drop('postal_cd',axis=1,inplace=True)
model_data_wdummies.drop('applicant_postal_cd',axis=1,inplace=True)
model_data_wdummies.shape


# ### Type of Product and Connection Used By (Don't exist in the new dataset anymore)

# In[60]:

#model_data_wdummies = pd.concat([model_data_wdummies, \
#                                 pd.get_dummies(model_data_wdummies.type_of_product,prefix='top')],axis=1)
#model_data_wdummies.drop('type_of_product',axis=1,inplace=True)
#model_data_wdummies.shape

#model_data_wdummies = pd.concat([model_data_wdummies, \
#                                 pd.get_dummies(model_data_wdummies.connection_used_by,prefix='cub')],axis=1)
#model_data_wdummies.drop('connection_used_by',axis=1,inplace=True)
#model_data_wdummies.shape


# -----------

# ## Cleaning - Bools

# ### Many Fields

# In[61]:

yn_fields = ['based_on_state_master_contract','pricing_confidentiality',
             'based_on_multiple_award_schedule','was_fcc_form470_posted',
             'includes_voluntary_extensions']

yn_map = {'Yes':True,'No':False}
for f in yn_fields:
    model_data_wdummies.loc[:,f] = model_data_wdummies[f].map(yn_map)
    model_data_wdummies.drop(f, axis=1, inplace=True)


# **Review Summary**

# In[62]:

s4 = summary(model_data)
s = s4.style.applymap(color_obeject)
s


# -------

# # Final Exports
# 
# 

# In[63]:

final_model_data = model_data_wdummies.copy(deep=True)


# In[64]:

#s5 = summary(final_model_data)
#s = s5.style.applymap(color_obeject)
#s
final_model_data.columns.tolist()


# ## Export List of Final Columns 

# This is the second list that we use to format the future (2017) data -- we write it out to use in the Future Data Featurizerm

# In[65]:

with open('model_versions/final_modeling_columns.pkl','w') as f:
    pickle.dump(final_model_data.columns.tolist(),f)


# ## Export Final Model Data 
# 
# ### Drop Rows With NA's

# In[66]:

print 'Before we Drop NA', final_model_data.shape
final_model_data = final_model_data.dropna()
print 'After we Drop NA', final_model_data.shape


# In[67]:

final_model_data.to_csv('data/model_data_output_pristine.csv', index=False, float_format='%.3f')


# --------------

# **Convert this notebook to a python file**

# In[2]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Featurizer_A_Main_2016_Data.ipynb', 'ESH_Featurizer_A_Main_2016_Data.py', main)


# # End 

# ----------
