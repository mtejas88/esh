
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
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",151)
get_ipython().magic(u'matplotlib inline')


# ------

# # Load 2016 Data

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


# Service Providers (2016)

# In[7]:

cur.execute("select name, reporting_name from fy2016.service_providers where reporting_name is not NULL")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
service_providers_2016 = pd.DataFrame(rows, columns=names)


# In[8]:

service_providers_2016.columns = ['service_provider_name', 'reporting_name']


# In[9]:

service_providers_2016.head()


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


# ---------

# -------

# # Data Merging
# 

# Find the unique columns in the metadata table and merge them with the raw table. 

# In[12]:

uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
full_mg = pd.merge(raw, metadata[uniq_cols], on='frn',how='left').copy(deep=True)

print full_mg.shape


# ** Limit to Broadband Type **

# In[13]:

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
full_mg['broadband'] = (full_mg.service_type == 'Data Transmission and/or Internet Access')     & (-full_mg.function.isin(broadband_types))
    
full_mg = full_mg[full_mg.broadband == True]


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


# ** Merge the Clean Cl_Connect_Category Column to the Raw+Metadata Table**

# In[16]:

full_mg = pd.merge(full_mg, clean[['cl_id','cl_connect_category','cl_exclude']], left_on='id', right_on='cl_id', how='left')
print full_mg.shape

full_mg = full_mg[(full_mg.cl_exclude == False)]
full_mg.drop('cl_exclude', axis=1, inplace=True)
print full_mg.shape

#print full_mg.shape
#full_mg = pd.merge(full_mg, clean[(clean.cl_exclude == False)][['cl_id','cl_connect_category']], \
#                   left_on='id',right_on='cl_id',how='inner')
#full_mg.shape


# **Attach Cleaned Service Providers**

# In[17]:

full_mg = full_mg.merge(service_providers_2016, on='service_provider_name',how='left')


# **Review Summary**

# In[18]:

connect_cat_summary = pd.concat([pd.DataFrame(full_mg['cl_connect_category'].value_counts()),           pd.DataFrame(full_mg['cl_connect_category'].value_counts(normalize=True))],          axis=1)

connect_cat_row_total = pd.DataFrame(full_mg['cl_connect_category'].value_counts()).reset_index()
connect_cat_summary.columns = ['Count','Percent']
connect_cat_summary


# --------

# # Cutting - Remove  "Uncategorized" as an Option Since
# 
# There are Too Few Observations  

# In[19]:

full_mg = full_mg[full_mg.cl_connect_category != 'Uncategorized']


# -----

# # Cleaning & Some Feature Creation 
# 
# The order of cleaning/cutting/feature creations is somewhat mixed because we are using some of the cutting to decide which fields to clean, etc. <br>  Ideally we would separate them into separate sequences of code logic - but this is ok. 

# ---------

# # Cleaning - Convert Cols to Float
# 
# Skip it if we can't convert to Float

# In[20]:

for col in full_mg.columns:
    try:
        full_mg[col] = full_mg[col].astype(float)
    except ValueError:
        continue


# **Review Summary**

# In[21]:

s1 = summary(full_mg)
s1.sort_values('col')


# --------

# # Cutting Features : Keep Fields less than 15% Null.

# In[22]:

mostly_not_null_cols = s1[s1.null_pct < .15]
model_data = full_mg[mostly_not_null_cols.col.tolist()]
model_data.shape


# ** Review Summary ** 

# In[23]:

s2 = summary(model_data)
s = s2.style.applymap(color_obeject)
s


# ---------

# # Cleaning:  Fill Some of the NA's

# ** We will Record Where We Fill an NA - Just so we know**

# In[24]:

model_data.is_copy = False ## Some silly Pandas thing here - to supress some of the warnings (not super important)
model_data.loc[:,'has_na_fill'] = False  ## Initialize the field 


# In[25]:

model_data.shape


# In[26]:

model_data.dropna().shape


# ## NA Strategy
# Being really intentional here about how we will fill values as some of these are very important in the estimation. Mostly just setting to "UNKNOWN" if the field is null. 

# **Type of Product Fill**

# In[27]:

model_data.loc[model_data.type_of_product.isnull(),'has_na_fill'] = True
model_data.loc[model_data.type_of_product.isnull(),'type_of_product'] = 'UNKNOWN'


# **Purpose**

# In[28]:

model_data.loc[model_data.purpose.isnull(),'has_na_fill'] = True
model_data.loc[model_data.purpose.isnull(),'purpose'] = 'UNKNOWN'


# **Upload and Download Speed**

# In[29]:

model_data.loc[model_data.download_speed.isnull(),'has_na_fill'] = True
model_data.loc[model_data.upload_speed.isnull(),'has_na_fill'] = True

model_data.loc[model_data.download_speed.isnull(),'download_speed'] = -9999
model_data.loc[model_data.upload_speed.isnull(),'upload_speed'] = -9999


# **Connection Used By**

# In[30]:

model_data.loc[model_data.connection_used_by.isnull(),'has_na_fill'] = True
model_data.loc[model_data.connection_used_by.isnull(),'connection_used_by'] = "UNKNOWN"


# **Review Summary**

# In[31]:

sNA = summary(model_data)
s = sNA.style.applymap(color_obeject)
s


# -----

# # Feature Creation - Narrative Dummy Creation

# ** First Add the Narrative Dummies **
# 
# We will iterate over the "extra_features" list and add a dummy column with a 1 or 0 if the word/phrase is present in the narrative field. You can add new words or phrases or delete the current ones by editing that list. 

# In[32]:

extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']

def assign_narrative_dummys(df):
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']
    for f in extra_features:
        df['dmy_'+f] = df.narrative.            apply(lambda x: True if f in str(x).lower().replace('-','') else False)
    return df
model_data = assign_narrative_dummys(model_data)


# In[33]:

print model_data.shape
model_data.iloc[:,-14:].head()


# ------

# # Cutting: Remove Columns Singular Columns and those with more than 100 Unique Values

# In[34]:

broadly_unique = sNA[(sNA.datatype == 'O') & (sNA.num_uniq > 100)].col.tolist() ## List of columns with more than 100 uniqvals
singular_cols = sNA[sNA.num_uniq == 1].col.tolist() ## list of singular columns
broadly_unique.remove('reporting_name') ## Remove Reporting Name from the list since we are going to do some work with it
model_data.drop(broadly_unique+singular_cols,axis=1,inplace=True)

model_data.shape


# **Review Summary**

# In[35]:

s3 = summary(model_data)
s3 = s3.style.applymap(color_obeject)

s3


# --------

# # Cutting:  Remove ID Fields
# 
# We can now cut the extra ID fields, or fields that represent unique id numbers. If we include these in the model it can "overfit" easily and just learn the value based on the unique, or semi-unique numbers. 

# ## Mark Id Columns

# In[36]:

id_cols = ['cl_id','frn', 'application_number','applicant_ben', 'line_item']


# In[37]:

## Execute the drop
model_data.drop(id_cols,axis=1,inplace=True)


# -------

# ## Export the Current Columns 
# 
# We need these so we can format later year data. We will need 2 lists to format future year data. 
# 
# 1. **List One** (This List) This list will have the primary columns (i.e. not a ton of dummy columns, though we do have the narrative dummies in here), and all the numeric fields we are keeping. 
# 2. **List Two** (Exported Later) This will have all fields including all dummies generated on the 2016 data. We will use that list to verify that the final structure in the future data matches the final structure in the 2016 data. 

# In[38]:

model_columns = model_data.columns.tolist()
model_columns.remove('has_na_fill')
model_columns.remove('cl_connect_category')

with open('model_versions/modeling_columns.pkl','w') as f:
    pickle.dump(model_columns,f)

len(model_columns)


# ------

# # Feature Creation: Standardize DL/UL Speeds 

# In[39]:

def std_speed_units(row, unit_col, speed_col):
    """Standardize the speed units, basicaaly if the speed col is not null, we check if the 
    speed col and the unit col make sense (if GBPS is it less than 101), if so we convert to mbps
    other wise we assumt that it is mpbs already. """
    if row[speed_col] is not None and not pd.isnull(row[speed_col]):
        if (row[speed_col] > 101) and (row[unit_col] == 'Gbps'):
            print row.id, 'has weird speed values. -- Verify'
            return row[speed_col]
        else:
            return row[speed_col] * {np.nan:1, None:1,'Mbps':1, 'Gbps':1000}[row[unit_col]] ## Picks 1 or 1000 based on the unit
    else:
        return None

def normailze_speed(df):
    """Fucntion to Execute whole process on a df
    we apply the std_speed_units() function to the DL and UL data"""
    df = df.copy(deep=True)
    df.upload_speed = df.upload_speed.astype(float)
    df.download_speed = df.download_speed.astype(float)

    df['std_upload_spd'] = df.apply(lambda row: std_speed_units(row,'upload_speed_units','upload_speed'),axis=1)
    df['std_download_spd'] = df.apply(lambda row: std_speed_units(row,'download_speed_units','download_speed'),axis=1)
    return df


# ** Execute the Normalization **

# In[40]:

model_data = normailze_speed(model_data)


# ------

# # Feature Creation - "Major" Service Provider Dummies

# In[41]:

major_service_provider = model_data.reporting_name.value_counts()


# ** Select only Those Service Providers that had 150+ Values **

# In[42]:

major_service_provider = major_service_provider[major_service_provider >= 150]
major_service_provider = major_service_provider.index.tolist()


# In[43]:

len(major_service_provider)


# **Assign the Dummies**

# In[44]:

for service_provider in major_service_provider:
    model_data.loc[model_data.reporting_name == service_provider,'dmy_'+service_provider] = True
    model_data['dmy_'+service_provider].fillna(False,inplace=True)


# **Delete the Reporting Name and Service Provider Number**

# In[45]:

del model_data['reporting_name']
del model_data['service_provider_number']


# ---------

# # Feature Creation - Make Categorical Dummies

# **Create a new dataframe - just helps if we want to expiriment with the dummies - don't have to run the whole script** 

# In[46]:

model_data_wdummies = model_data.drop(['upload_speed_units','upload_speed','download_speed_units','download_speed'],axis=1)


# ## Multiclass Dummies

# We will assign what the top service providers are in this dataset - but later will limit it to what matches the 2016 data.

# ### Purpose

# Purpose has really long values - so i have created a key to translate them to something shorter (`translate_purpose` list below).
# 
# Simplify the purpose labels and then assign dummies
# 
# **Note** : Use of the prefix argument in `pd.get_dummies() ` that is how we differentiate the different dummy columns.

# **WARNING** -- Watch the Endoding When Dealing With New Data - Verify it is UTF-8 and that you aren't getting null values out of the map because of weird text encoding stuff. 

# In[47]:

translate_purpose = dict(zip([
       'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider',
       'Data Connection between two or more sites entirely within the applicant\xe2\x80\x99s network',
       'Data connection(s) for an applicant\xe2\x80\x99s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately',
       'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)',
       'Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities',
       'UNKNOWN'],['ias_includes_connection','data_connect_2ormore','data_connect_hub','ias_no_circuit','backbone','UNKNOWN']))

## Translate the Purpose to the short values using the map method
model_data_wdummies.purpose = model_data_wdummies.purpose.map(translate_purpose)


# In[48]:

model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.purpose,prefix='purp')],axis=1)
model_data_wdummies.drop('purpose',axis=1,inplace=True)


# ### Function

# Like purpose we will translate the function values using a dictionary.

# In[49]:

model_data.function.unique().tolist()


# In[50]:

function_dict = dict(zip([u'Fiber', u'Copper', u'Fiber Maintenance & Operations', u'Wireless', u'Other'],                             ['fiber','copper','fiber_mat_ops','wireless','other']))
model_data_wdummies.function = model_data_wdummies.function.map(function_dict)
## Attach
model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.function,prefix='fnct')],axis=1)
model_data_wdummies.drop('function',axis=1,inplace=True)


# ### Type of Product

# Assign the dummies

# In[51]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.type_of_product,prefix='top')],axis=1)
model_data_wdummies.drop('type_of_product',axis=1,inplace=True)
model_data_wdummies.shape


# ### Connection Used BY

# Assign the dummies

# In[52]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connection_used_by,prefix='cub')],axis=1)
model_data_wdummies.drop('connection_used_by',axis=1,inplace=True)
model_data_wdummies.shape


# ### States

# Assign the dummies

# In[53]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.postal_cd,prefix='st')],axis=1)
model_data_wdummies.drop('postal_cd',axis=1,inplace=True)
model_data_wdummies.shape


# -----------

# ## Cleaning - Bools

# ### Many Fields

# In[54]:

yn_fields = ['connected_directly_to_school_library_or_nif','basic_firewall_protection',
             'connection_supports_school_library_or_nif','lease_or_non_purchase_agreement',
             'based_on_state_master_contract','pricing_confidentiality',
             'based_on_multiple_award_schedule','was_fcc_form470_posted',
             'includes_voluntary_extensions'
            ]

yn_map = {'Yes':True,'No':False}
for f in yn_fields:
    model_data_wdummies.loc[:,f] = model_data_wdummies[f].map(yn_map)


# **Review Summary**

# In[55]:

s4 = summary(model_data)
s = s4.style.applymap(color_obeject)

s


# -------

# # Final Exports
# 
# 

# In[56]:

final_model_data = model_data_wdummies.copy(deep=True)


# ## Export List of Final Columns 

# This is the second list that we use to format the future (2017) data -- we write it out to use in the Future Data Featurizerm

# In[57]:

with open('model_versions/final_modeling_columns.pkl','w') as f:
    pickle.dump(final_model_data.columns.tolist(),f)


# ## Export Final Model Data 
# 
# ### Drop Rows With NA's

# In[58]:

print 'Before we Drop NA', final_model_data.shape
final_model_data = final_model_data.dropna()
print 'After we Drop NA', final_model_data.shape


# In[59]:

final_model_data.to_csv('data/model_data_output_June16_2017.csv', index=False)


# --------------

# **Convert this notebook to a python file**

# In[3]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Featurizer_A_Main_2016_Data_dk.ipynb', 'ESH_Featurizer_A_Main_2016_Data_dk.py', main)


# # End 

# ----------
