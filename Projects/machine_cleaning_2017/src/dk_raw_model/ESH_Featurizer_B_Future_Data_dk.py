
# coding: utf-8

# ---------

# ![title](DataKind_orange_small.png)
# 

# ------------

# # TITLE: ESH Featurizer Future Data

# # Summary
# 
# In this file we will format future data (2017) into the format needed to use the model generated from the 2016 data. 

# -------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ------

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
pd.set_option("display.max_rows",200)
get_ipython().magic(u'matplotlib inline')


# -----

# # Load 2017 Data

# Establishing the PostgreSQL connection

# In[3]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Raw FRN Line Items (2017)

# In[4]:

cur.execute("select * from fy2017.frn_line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2017)

# In[5]:

cur.execute("select * from fy2017.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Service Providers (2016)

# In[6]:

cur.execute("select name, reporting_name from fy2016.service_providers where reporting_name is not NULL")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
service_providers_2016 = pd.DataFrame(rows, columns=names)


# In[7]:

service_providers_2016.columns = ['service_provider_name', 'reporting_name']


# Loading Dataset from Local Files (Optional)

# In[8]:

#raw = pd.read_csv('LocalLargeFiles/fy2017_frn_line_items',low_memory=False)
#metadata = pd.read_csv('LocalLargeFiles/fy2017_frns',low_memory=False)
#service_providers_2016 = pd.read_csv('local_data/service_providers_2016.csv')


# # Local Helper Functions

# In[9]:

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
    Takes a scalar and returns a string with
    the css property `'color: red'` for negative
    strings, black otherwise.
    """
    color = 'red' if val == 'O' else 'black'
    return 'color: %s' % color

def color_code_summary(df):
    s = summary(df)
    style_s = s.style.applymap(color_obeject)
    return s, style_s


# -----------

# # Data Merging
# 

# Find the unique columns in the metadata table and merge them with the raw table. 

# In[10]:

uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
mg_raw = pd.merge(raw, metadata[uniq_cols], on='frn', how='left')

print mg_raw.shape
print metadata.shape
print raw.shape


# In[11]:

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


# In[12]:

full_mg = mg_raw[mg_raw.broadband == True]
full_mg.shape


# **Attach Cleaned Service Providers**

# In[13]:

full_mg = full_mg.merge(service_providers_2016,on='service_provider_name',how='left')


# -----------

# # Cleaning & Some Feature Creation 
# 
# The order of cleaning/cutting/feature creations is somewhat mixed because we are using some of the cutting to decide which fields to clean, etc. <br>  Ideally we would separate them into separate sequences of code logic - but this is ok. 

# ------

# # Cleaning - Convert Cols to Float
# 
# Skip it if we can't convert to Float

# In[14]:

float_count= 0
obj_count = 0
for col in full_mg.columns:
    try:
        full_mg[col] = full_mg[col].astype(float)
        float_count += 1
    except (ValueError, TypeError):
        obj_count += 1
        continue
print 'Total Float Cols:', float_count,' -- Float Percent:', float_count/(1.0*len(full_mg.columns))
print 'Total Object Cols:', obj_count, ' -- Object Percent:', obj_count/(1.0*len(full_mg.columns))


# -----

# # Feature Creation - Create Narrative Dummies

# In[15]:

full_mg.narrative[0:10]
#full_mg['narrative'].replace('None', 'no_narrative', inplace=True)
full_mg['narrative'].fillna(value='no_narrative', inplace = True)


# In[16]:

## TODO - Maybe provide multiple words for each type instead of just a column for each word
def assign_narrative_dummys(df):
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber','copper','wan','t3','t1','wireless','microwave']
    for f in extra_features:
        df['dmy_'+f] = df.narrative.            apply(lambda x: True if f in x.lower().replace('-','') else False)
    return df
full_mg = assign_narrative_dummys(full_mg)


# **Review Result**

# In[17]:

full_mg.iloc[0:10,-14:]


# **Review Summary**

# In[18]:

s1 = summary(full_mg)
s1.sort_values('col')


# --------

# # Cutting: Column Selection - First Pass
# 
# **Keep Only Those Base Columns That are in the Model Data**
# 
# Based on the First List we export in the 2016 featurizer code. We are picking the main columns to keep here, not dealing with the full list of dummy columns we will eventually need.  Column lists were exported in `ESH_Featurizer_A_Main_2016_Data.ipynb`.

# **Load the Initial List of Columns**

# In[19]:

modeling_columns = pickle.load(open('model_versions/modeling_columns.pkl', 'rb'))


# In[20]:

model_data = full_mg[modeling_columns]
model_data.shape


# **Review Summary**

# In[21]:

s2 = summary(model_data)
s = s2.style.applymap(color_obeject)
s


# ------

# # Cleaning: NA Review 
# 
# Unlike in the 2016 featurizer - we can't just remove columns with lots of nulls, we have to make sure that the columns used in 2016 are present in this new years data - otherwise the model will not work. 

# ## Check for Fields With Lots of NA's
# -- In the Training Data (2016) All these Fields had Low NA Percentage

# **Check What Has a High NA Percentage in the Current Year Data**

# In[22]:

s2[s2.null_pct>.15]


# ** DataKind Suggest using best judgement here - either assign UNKNOWN - or the most common field. **
# 
# **NOTE**: When something is "occasionally" null in the 2016 data but heavily null in the later year data you need to examine and make sure there isn't a consistent pattern of chagne in the new data. The main concern would be if the we fill in the 2017 data with all "UNKNOWN" values but they represent something different than those few "UNKNOWN" found int he 2016 data. 
# 
# 

# -------

# # Cleaning: Fill Some of the NA's

# ** We will Record Where We Fill and NA **

# In[23]:

model_data.is_copy = False ## <--Pandas thing - not a big deal to understand (prevents false warnings)
model_data['has_na_fill'] = False


# In[24]:

model_data.shape


# ## NA Strategy
# Being really intentional here about how we will fill values as some of these are very important in the estimation. Mostly just setting to "UNKNOWN" if the field is null. 

# **Type of Product Fill**

# In[25]:

model_data.loc[model_data.type_of_product.isnull(),'has_na_fill'] = True
model_data.loc[model_data.type_of_product.isnull(),'type_of_product'] = 'UNKNOWN'


# **Purpose**

# In[26]:

model_data.loc[model_data.purpose.isnull(),'has_na_fill'] = True
model_data.loc[model_data.purpose.isnull(),'purpose'] = 'UNKNOWN'


# **Upload and Download Speed**

# In[27]:

model_data.loc[model_data.download_speed.isnull(),'has_na_fill'] = True
model_data.loc[model_data.upload_speed.isnull(),'has_na_fill'] = True

model_data.loc[model_data.download_speed.isnull(),'download_speed'] = -9999
model_data.loc[model_data.upload_speed.isnull(),'upload_speed'] = -9999


# **Connection Used By**

# In[28]:

model_data.loc[model_data.connection_used_by.isnull(),'has_na_fill'] = True
model_data.loc[model_data.connection_used_by.isnull(),'connection_used_by'] = "UNKNOWN"


# **Review the Summary**

# In[29]:

sNA = summary(model_data)
s = sNA.style.applymap(color_obeject)
s


# -----

# -----

# # Cleaning - Manual Correction Area

# This area of code (from title above down to *Feature Creation: Standardize DL/UL Speeds * ) can be used to change values that are new in the current data, or just explore whether such moves are needed. 
# 
# As an example we looked at the Type of Product field - which had new values that were not present in 2016 data. We import the 2016 data so we can compare. 

# --------

# ## Type of Product 
# There are some new values here - You Could Map them to Old Values Maybe

# In[30]:

modeldata2016 = pd.read_csv('data/model_data_output_June16_2017.csv')


# In[31]:

top2016 = pd.DataFrame(modeldata2016[[i for i in modeldata2016.columns if 'top' in i]].T.sum(axis=1))
top2016['2016_perc'] = top2016/top2016.sum()
top2016.columns = ['2016','2016_perc']
top2016.index = [i.replace('top_','') for i in top2016.index]

topCurent = pd.DataFrame(model_data.type_of_product.value_counts())
topCurent['Current_perc'] = topCurent/topCurent.sum()
topCurent.columns = ['Current','Current_perc']



# In[32]:

cnct = pd.concat([top2016, topCurent],axis=1)


# **Compare Distribution of Current Year to 2016**

# In[33]:

cnct[['Current_perc','2016_perc']].plot(kind='bar',figsize=(14,6))


# **Check what categories were not present in 2016**

# In[34]:

cnct[cnct['2016'].isnull()]


# ** We are just going to remove these for now - BUT there is likely a logical way to reassign these **
# There are only a handful and they don't have a lot of values.
# 
# **Note**: We might want to limit the options on Type of Product in the original modeling data - maybe just select those that have more than some threshold.

# ---------

# # Feature Creation: Standardize DL/UL Speeds 

# In[35]:

def std_speed_units(row, unit_col, speed_col):
    if row[speed_col] is not None and not pd.isnull(row[speed_col]):
        if (row[speed_col] > 101) and (row[unit_col] == 'Gbps'):
            print row.id, 'has weird speed values. -- Verify'
            return row[speed_col]
        else:
            return row[speed_col] * {np.nan:1, None:1,'Mbps':1, 'Gbps':1000}[row[unit_col]]
    else:
        return None

def normailze_speed(df):
    df = df.copy(deep=True)
    df.upload_speed = df.upload_speed.astype(float)
    df.download_speed = df.download_speed.astype(float)

    df['std_upload_spd'] = df.apply(lambda row: std_speed_units(row,'upload_speed_units','upload_speed'),axis=1)
    df['std_download_spd'] = df.apply(lambda row: std_speed_units(row,'download_speed_units','download_speed'),axis=1)
    return df


# In[36]:

model_data = normailze_speed(model_data)


# -------

# # Feature Creation - Make Categorical Dummies

# **Create a new dataframe - just helps if we want to expiriment with the dummies - don't have to run the whole script** 

# In[37]:

model_data_wdummies = model_data.drop(['upload_speed_units','upload_speed','download_speed_units','download_speed'],axis=1)


# ## Multiclass Dummies
# 
# We will assign what the top service providers are in this dataset - but later will limit it to what matches the 2016 data. 

# In[38]:

major_service_provider = model_data_wdummies.reporting_name.value_counts()


# In[39]:

major_service_provider = major_service_provider[major_service_provider >= 150]
major_service_provider = major_service_provider.index.tolist()


# In[40]:

for service_provider in major_service_provider:
    model_data_wdummies.loc[model_data_wdummies.reporting_name == service_provider,'dmy_'+service_provider] = True
    model_data_wdummies['dmy_'+service_provider].fillna(False,inplace=True)


# In[41]:

del model_data_wdummies['reporting_name']
del model_data_wdummies['service_provider_number']


# ### Purpose

# Simplify the purpose labels and then assign dummies
# 
# **Note** : Use of the prefix argument in `pd.get_dummies() ` that is how we differentiate the different dummy columns.

# **WARNING** -- Watch the Endoding When Dealing With New Data - Verify it is UTF-8 and that you aren't getting null values out of the map because of weird text encoding stuff. 

# In[42]:

translate_purpose = dict(zip([
       'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider',
       'Data Connection between two or more sites entirely within the applicant\xe2\x80\x99s network',
       'Data connection(s) for an applicant\xe2\x80\x99s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately',
       'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)',
       'Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities',
       'UNKNOWN'],['ias_includes_connection','data_connect_2ormore','data_connect_hub','ias_no_circuit','backbone','UNKNOWN']))

## Translate the Purpose to the short values using the map method
model_data_wdummies.purpose = model_data_wdummies.purpose.map(translate_purpose)


# In[43]:

model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.purpose,prefix='purp')],axis=1)
model_data_wdummies.drop('purpose',axis=1,inplace=True)


# ### Function

# Simplify function values and then assign dummies

# In[44]:

model_data.function.unique().tolist()


# In[45]:

function_dict = dict(zip([u'Fiber', u'Copper', u'Fiber Maintenance & Operations', u'Wireless', u'Other'],                             ['fiber','copper','fiber_mat_ops','wireless','other']))
model_data_wdummies.function = model_data_wdummies.function.map(function_dict)
## Attach
model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.function,prefix='fnct')],axis=1)
model_data_wdummies.drop('function',axis=1,inplace=True)


# ### Type of Product

# Just assign the Type of Product Dummies

# In[46]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.type_of_product,prefix='top')],axis=1)
model_data_wdummies.drop('type_of_product',axis=1,inplace=True)
model_data_wdummies.shape


# ### Connection Used BY

# Just assign the Connection Used By Dummies

# In[47]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connection_used_by,prefix='cub')],axis=1)
model_data_wdummies.drop('connection_used_by',axis=1,inplace=True)
model_data_wdummies.shape


# ### States

# Assign State Dummies

# In[48]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.postal_cd,prefix='st')],axis=1)
model_data_wdummies.drop('postal_cd',axis=1,inplace=True)
model_data_wdummies.shape


# -----

# ## Cleaning - Bools

# Convert these fields to to True/False

# ### Many Fields

# In[49]:

yn_fields = ['connected_directly_to_school_library_or_nif','basic_firewall_protection',
             'connection_supports_school_library_or_nif','lease_or_non_purchase_agreement',
             'based_on_state_master_contract','pricing_confidentiality',
             'based_on_multiple_award_schedule','was_fcc_form470_posted',
             'includes_voluntary_extensions'
            ]

yn_map = {'Yes':True,'No':False}
for f in yn_fields:
    model_data_wdummies.loc[:,f] = model_data_wdummies[f].map(yn_map)


# In[50]:

model_data_wdummies.head()


# **Review Summary**

# In[51]:

s1, s1s = color_code_summary(model_data_wdummies)


# In[52]:

s1s


# -------

# # Conform Future Data to the 2016 Data 

# ## Load in the Final Modeling Columns That Include all Dummies

# In[53]:

final_modeling_columns = pickle.load(open('model_versions/final_modeling_columns.pkl', 'rb'))


# In[54]:

print "In the 2016 modeling data we had {0} columns, we currently have {1} columns. "    .format(len(final_modeling_columns),model_data_wdummies.shape[1])
## Need to make sure the columns match 


# ----

# ## Drop Columns and Rows for Data That Did Not Exist in 2016

# **Which Columns Are Not Present**

# In[55]:

diff_from_2016 = set(final_modeling_columns) - set(model_data_wdummies.columns.tolist())
diff_in_current_year = set(model_data_wdummies.columns.tolist()) - set(final_modeling_columns)


# In[56]:

print "These are the columns present in 2016 but not current year:"
print diff_from_2016
print ' '
print '*'*10
print 'These are the columns present in the current year but not in 2016:'
print diff_in_current_year


# ## Delete New Columns (Not in 2016 Data )

# In[57]:

print model_data_wdummies.shape
for item in list(diff_in_current_year):
    model_data_wdummies = model_data_wdummies[model_data_wdummies[item] == 0]
    del model_data_wdummies[item]
print model_data_wdummies.shape


# ## Create Empty Columns For Data That Does Not Exist in Current Year

# In[58]:

diff_from_2016 = list(diff_from_2016)
diff_from_2016.remove('cl_connect_category') ## DO NOT CREATE CL_CONNECT_CATEFORY !! --> We don't have that info. 
diff_from_2016

for col in diff_from_2016:
    model_data_wdummies[col] = 0
print model_data_wdummies.shape


# ### Make Sure the Columns Are in the Matching Order as 2016 Data

# In[59]:

model_data_wdummies = model_data_wdummies[[i for i in final_modeling_columns if i != 'cl_connect_category']]


# In[60]:

model_data_wdummies.shape


# ## Drop Anything Else with an NA

# In[61]:

print model_data_wdummies.shape
final_model_data = model_data_wdummies.dropna()
final_model_data.shape


# In[62]:

final_model_data.to_csv('data/featurized_2017_data.csv', index=False)


# --------------

# # Verify The Datasets Match (Optional) '
# 
# This is more of a sanity check section. 

# In[63]:

data2016 = pd.read_csv('data/model_data_output_June16_2017.csv')


# In[64]:

data2016.drop('cl_connect_category',axis=1, inplace=True)


# In[65]:

data2016.shape


# In[66]:

final_model_data.shape


# **Review**
# 
# Just looking to make sure the data looks similar - comparing one 2016 row to a 2017 row.

# In[67]:

pd.concat([pd.DataFrame(final_model_data.ix[0],columns=['2017']),pd.DataFrame(data2016.ix[0],columns=['2016'])],axis=1)


# **Note**: In python `0` and `False` are equal and `1` and `True` are equal - So some differences in those columns are acceptable.

# **Example (Adrianna Delete if you want)**

# In[68]:

print 0 == False
print 1 == True


# ----

# **Convert this notebook to a python file**

# In[2]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Featurizer_B_Future_Data_dk.ipynb', 'ESH_Featurizer_B_Future_Data_dk.py', main)


# # End

# -------
