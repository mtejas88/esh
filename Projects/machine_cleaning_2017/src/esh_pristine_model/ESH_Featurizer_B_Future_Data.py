
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

# In[2]:

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
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",200)
get_ipython().magic(u'matplotlib inline')


# -----

# # Load 2017 Data

# Establishing the PostgreSQL connection for PRIS2017

# In[3]:

HOST = os.environ.get("HOST_PRIS2017")
USER = os.environ.get("USER_PRIS2017")
PASSWORD = os.environ.get("PASSWORD_PRIS2017")
DB = os.environ.get("DB_PRIS2017")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# FRN Line Items (2017, Pristine)

# In[4]:

cur.execute("select * from public.esh_line_items where funding_year=2017")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw = pd.DataFrame(rows, columns=names)


# In[5]:

## in 2017, the open_flags are in a different dataset
cur.execute("select flaggable_id, count(label) as num_open_flags, array_agg(label) as open_flag_labels             from public.flags where funding_year=2017 and flaggable_type='LineItem'            and status='open' group by flaggable_id")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
rawflags= pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2017)

# In[6]:

cur.execute("select * from fy2017.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata = pd.DataFrame(rows, columns=names)


# Service Providers (2016)

# In[7]:

cur.execute("select name, reporting_name from fy2016.service_providers where reporting_name is not NULL")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
service_providers_2016 = pd.DataFrame(rows, columns=names)


# In[8]:

service_providers_2016.columns = ['service_provider_name', 'reporting_name']


# Loading Dataset from Local Files (Optional)

# In[9]:

#raw = pd.read_csv('LocalLargeFiles/fy2017_frn_line_items',low_memory=False)
#metadata = pd.read_csv('LocalLargeFiles/fy2017_frns',low_memory=False)
#service_providers_2016 = pd.read_csv('local_data/service_providers_2016.csv')


# # Local Helper Functions

# In[10]:

def summary(df):
    summary_list = []
    print 'SHAPE', df.shape
    
    for i in df.columns:
        #print i
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


# -----------------------

# # Data Merging
# 

# Find the unique columns in the metadata table and merge them with the raw table. 

# In[11]:

## 2017
## combine flag info with raw2017, merge flaggable_id with id
raw = pd.merge(raw, rawflags, left_on='id', right_on='flaggable_id', how='left')
raw.frn_complete = raw.frn_complete.astype(str)

## create the FRN id from the FRN_complete id
def fix_frn(df, col):
    frn_list = []
    for row in df[col]:
        if row != "Unknown":
            try:
                #frn_list.append(int(re.split(r"\.\s*", row)[0]))
                frn_list.append(re.split(r"\.\s*", row)[0])
            except:
                frn_list.append(None)
        else:
            frn_list.append(None)

    df['frn'] = frn_list
    return(df)

raw = fix_frn(raw, "frn_complete")
#metadata = fix_frn(metadata, "frn")

## merge in columns that don't exist already in metadata
uniq_cols= ['frn']+list(set(metadata.columns.tolist()) - set(raw.columns.tolist()))
full_mg = pd.merge(raw, metadata[uniq_cols], on='frn', how='left')
print full_mg.shape
print metadata.shape
print raw.shape


# ** Limit to Broadband Type **

# In[12]:

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
#mg_raw['broadband'] = (mg_raw.service_type == 'Data Transmission and/or Internet Access') & (-mg_raw.function.isin(broadband_types))

## now can subset just to broadband line items
full_mg = full_mg[full_mg.broadband == True]
full_mg.shape


# **Attach Cleaned Service Providers**

# In[13]:

full_mg = full_mg.merge(service_providers_2016, on='service_provider_name', how='left')


# -----------

# # Cleaning & Some Feature Creation 
# 
# The order of cleaning/cutting/feature creations is somewhat mixed because we are using some of the cutting to decide which fields to clean, etc. <br>  Ideally we would separate them into separate sequences of code logic - but this is ok. 

# ------

# # Cleaning - Convert Cols to Float

# Treat Certain Columns Separately

# In[14]:

## force service_category to INT
#full_mg.loc[:,'service_category'] = full_mg.service_category.apply(make_int)
## force bandwidth_in_mbps to INT
full_mg.loc[:,'bandwidth_in_mbps'] = full_mg.bandwidth_in_mbps.apply(make_int)
## force upload_bandwidth_in_mbps to INT
full_mg.loc[:,'upload_bandwidth_in_mbps'] = full_mg.upload_bandwidth_in_mbps.apply(make_int)
## treat the number of lines variable ("1" vs "1.0")
full_mg.loc[:,'num_lines'] = full_mg.num_lines.apply(make_int)
#full_mg = treat_tough_string_vars("num_lines")


# In[15]:

## drop columns
full_mg.drop('created_at', axis=1, inplace=True)
full_mg.drop('updated_at', axis=1, inplace=True)


# Skip it if we can't convert to Float

# In[16]:

## Skip it if we can't convert to Float or if we already treated it
cols_already_converted = ['bandwidth_in_mbps', 'upload_bandwidth_in_mbps', 'num_lines',                          'open_flag_labels', 'open_tag_labels', 'frn_complete']

float_count= 0
obj_count = 0
for col in full_mg.columns:
    print col
    if col not in cols_already_converted:
        try:
            full_mg[col] = full_mg[col].astype(float)
            float_count += 1
        except (ValueError, TypeError):
            print "ERROR"
            obj_count += 1
            continue
print 'Total Float Cols:', float_count,' -- Float Percent:', float_count/(1.0*len(full_mg.columns))
print 'Total Object Cols:', obj_count, ' -- Object Percent:', obj_count/(1.0*len(full_mg.columns))


# In[17]:

full_mg.dtypes


# -----

# # Feature Creation - Open Flags and Tags

# ** Need to Break out the Open Flags Columns **

# We will iterate over the "open_flags" list and add a dummy column with a 1 or 0 if the flag is in the open_flag_labels field. (Since the open_flag_labels is empty for every row, we don't treat it.)

# In[18]:

def assign_flag_dummys(df):
    open_flags = ['unknown_conn_type','unknown_quantity','product_bandwidth',                  'not_upstream', 'not_isp','not_bundled_ia','not_wan',                  'fiber_maintenance','flipped_speed','special_construction','not_broadband']
    for flag in open_flags:
        df.loc[:,'flag_'+flag] = df.open_flag_labels.apply(lambda x: True if flag in x else False)
    return df


# In[19]:

## apply definition above
full_mg.is_copy = False
full_mg.open_flag_labels = full_mg.open_flag_labels.astype(str)
full_mg = assign_flag_dummys(full_mg)


# # Feature Creation - Create Narrative Dummies

# ** First Add the Narrative Dummies **
# 
# We will iterate over the "extra_features" list and add a dummy column with a 1 or 0 if the word/phrase is present in the narrative field. You can add new words or phrases or delete the current ones by editing that list. 

# In[20]:

## TODO - Maybe provide multiple words for each type instead of just a column for each word
def assign_narrative_dummys(df):
    extra_features = ['isp','fiber','cable','dsl','lit fiber','dark fiber',                      'copper','wan','t3','t1','wireless','microwave']
    for f in extra_features:
        df['dmy_'+f] = df.narrative.apply(lambda x: True if f in x.lower().replace('-','') else False)
    return df

full_mg.narrative = full_mg.narrative.astype(str)
full_mg = assign_narrative_dummys(full_mg)


# **Review Result**

# In[21]:

full_mg.iloc[0:10,-14:]


# **Review Summary**

# In[22]:

s1 = summary(full_mg)
s1.sort_values('col')


# --------

# # Cutting: Column Selection - First Pass
# 
# **Keep Only Those Base Columns That are in the Model Data**
# 
# Based on the First List we export in the 2016 featurizer code. We are picking the main columns to keep here, not dealing with the full list of dummy columns we will eventually need.  Column lists were exported in `ESH_Featurizer_A_Main_2016_Data.ipynb`.

# **Load the Initial List of Columns**

# In[23]:

modeling_columns = pickle.load(open('model_data_versions/modeling_columns.pkl', 'rb'))


# In[24]:

model_data = full_mg[modeling_columns]
model_data.shape


# **Review Summary**

# In[25]:

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

# In[26]:

## just num_open_flags, which just means that there are less flags in 2017, but we will take it out in both.
to_drop_in_2016 = 'num_open_flags'
s2[s2.null_pct>.15]


# ** DataKind Suggest using best judgement here - either assign UNKNOWN - or the most common field. **
# 
# **NOTE**: When something is "occasionally" null in the 2016 data but heavily null in the later year data you need to examine and make sure there isn't a consistent pattern of chagne in the new data. The main concern would be if the we fill in the 2017 data with all "UNKNOWN" values but they represent something different than those few "UNKNOWN" found in the 2016 data. 
# 
# 

# -------

# # Cleaning: Fill Some of the NA's

# ** We will Record Where We Fill and NA **

# In[27]:

model_data.is_copy = False ## <--Pandas thing - not a big deal to understand (prevents false warnings)
#model_data['has_na_fill'] = False


# In[28]:

model_data.shape


# ## NA Strategy
# Being really intentional here about how we will fill values as some of these are very important in the estimation. Mostly just setting to "UNKNOWN" if the field is null. 

# ** No NAs in new data for all following variables **

# **Type of Product Fill**

# In[29]:

#model_data.loc[model_data.type_of_product.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.type_of_product.isnull(),'type_of_product'] = 'UNKNOWN'


# **Purpose**

# In[30]:

#model_data.loc[model_data.purpose.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.purpose.isnull(),'purpose'] = 'UNKNOWN'


# **Upload and Download Speed**

# In[31]:

#model_data.loc[model_data.download_speed.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.upload_speed.isnull(),'has_na_fill'] = True

#model_data.loc[model_data.download_speed.isnull(),'download_speed'] = -9999
#model_data.loc[model_data.upload_speed.isnull(),'upload_speed'] = -9999


# **Connection Used By**

# In[32]:

#model_data.loc[model_data.connection_used_by.isnull(),'has_na_fill'] = True
#model_data.loc[model_data.connection_used_by.isnull(),'connection_used_by'] = "UNKNOWN"


# **Review the Summary**

# In[33]:

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

# ## Don't Need To Do This Anymore Since Type of Product Doesn't Exist Anymore

# ## Type of Product 
# There are some new values here - You Could Map them to Old Values Maybe

# In[34]:

#modeldata2016 = pd.read_csv('../data/model_data_versions/model_data_output_pristine.csv')


# In[35]:

#top2016 = pd.DataFrame(modeldata2016[[i for i in modeldata2016.columns if 'top' in i]].T.sum(axis=1))
#top2016['2016_perc'] = top2016/top2016.sum()
#top2016.columns = ['2016','2016_perc']
#top2016.index = [i.replace('top_','') for i in top2016.index]

#topCurent = pd.DataFrame(model_data.type_of_product.value_counts())
#topCurent['Current_perc'] = topCurent/topCurent.sum()
#topCurent.columns = ['Current','Current_perc']


# In[36]:

#cnct = pd.concat([top2016, topCurent],axis=1)


# **Compare Distribution of Current Year to 2016**

# In[37]:

#cnct[['Current_perc','2016_perc']].plot(kind='bar',figsize=(14,6))


# **Check what categories were not present in 2016**

# In[38]:

#cnct[cnct['2016'].isnull()]


# ** We are just going to remove these for now - BUT there is likely a logical way to reassign these **
# There are only a handful and they don't have a lot of values.
# 
# **Note**: We might want to limit the options on Type of Product in the original modeling data - maybe just select those that have more than some threshold.

# ---------

# # Feature Creation: Standardize DL/UL Speeds 

# In[39]:

#def std_speed_units(row, unit_col, speed_col):
#    if row[speed_col] is not None and not pd.isnull(row[speed_col]):
#        if (row[speed_col] > 101) and (row[unit_col] == 'Gbps'):
#            print row.id, 'has weird speed values. -- Verify'
#            return row[speed_col]
#        else:
#            return row[speed_col] * {np.nan:1, None:1,'Mbps':1, 'Gbps':1000}[row[unit_col]]
#    else:
#        return None

#def normailze_speed(df):
#    df = df.copy(deep=True)
#    df.upload_speed = df.upload_speed.astype(float)
#    df.download_speed = df.download_speed.astype(float)
#    df['std_upload_spd'] = df.apply(lambda row: std_speed_units(row,'upload_speed_units','upload_speed'),axis=1)
#    df['std_download_spd'] = df.apply(lambda row: std_speed_units(row,'download_speed_units','download_speed'),axis=1)
#    return df


# ** Execute the Normalization -- Don't Need to Anymore **

# In[40]:

#model_data = normailze_speed(model_data)


# -------

# # Feature Creation - Make Categorical Dummies

# **Create a new dataframe - just helps if we want to experiment with the dummies - don't have to run the whole script** 

# In[41]:

#model_data_wdummies = model_data.drop(['upload_speed_units','upload_speed','download_speed_units','download_speed'], axis=1)
model_data_wdummies = model_data


# ## Multiclass Dummies
# 
# We will assign what the top service providers are in this dataset - but later will limit it to what matches the 2016 data. 

# In[42]:

major_service_provider = model_data_wdummies.reporting_name.value_counts()


# In[43]:

major_service_provider = major_service_provider[major_service_provider >= 150]
major_service_provider = major_service_provider.index.tolist()


# In[44]:

for service_provider in major_service_provider:
    model_data_wdummies.loc[model_data_wdummies.reporting_name == service_provider,'dmy_'+service_provider] = True
    model_data_wdummies['dmy_'+service_provider].fillna(False,inplace=True)


# In[45]:

del model_data_wdummies['reporting_name']
del model_data_wdummies['service_provider_number']


# ### Purpose

# Simplify the purpose labels and then assign dummies
# 
# **Note** : Use of the prefix argument in `pd.get_dummies() ` that is how we differentiate the different dummy columns.

# **WARNING** -- Watch the Endoding When Dealing With New Data - Verify it is UTF-8 and that you aren't getting null values out of the map because of weird text encoding stuff. 

# In[46]:

translate_purpose = dict(zip([
       'Internet access service that includes a connection from any applicant site directly to the Internet Service Provider',
       'Data Connection between two or more sites entirely within the applicant\xe2\x80\x99s network',
       'Data connection(s) for an applicant\xe2\x80\x99s hub site to an Internet Service Provider or state/regional network where Internet access service is billed separately',
       'Internet access service with no circuit (data circuit to ISP state/regional network is billed separately)',
       'Backbone circuit for consortium that provides connectivity between aggregation points or other non-user facilities',
       'UNKNOWN'],['ias_includes_connection','data_connect_2ormore','data_connect_hub','ias_no_circuit','backbone','UNKNOWN']))

## Translate the Purpose to the short values using the map method
model_data_wdummies.purpose = model_data_wdummies.purpose.map(translate_purpose)


# In[47]:

model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.purpose,prefix='purp')],axis=1)
model_data_wdummies.drop('purpose',axis=1,inplace=True)


# ### Function

# Simplify function values and then assign dummies

# In[48]:

model_data.function.unique().tolist()


# In[49]:

function_dict = dict(zip([u'Fiber', u'Copper', u'Fiber Maintenance & Operations', u'Wireless', u'Other'],                             ['fiber','copper','fiber_mat_ops','wireless','other']))
model_data_wdummies.function = model_data_wdummies.function.map(function_dict)
## Attach
model_data_wdummies = pd.concat([model_data_wdummies,                                 pd.get_dummies(model_data_wdummies.function,prefix='fnct')],axis=1)
model_data_wdummies.drop('function',axis=1,inplace=True)


# ### Connect Type

# In[50]:

## to avoid SettingWithCopyWarning
pd.options.mode.chained_assignment = None

## combine N/A and UNKNOWN values
model_data_wdummies.connect_type[model_data_wdummies.connect_type == 'N/A'] = 'UNKNOWN'
## since we believe that districts with Special Construction had a separate form last year
## take out rows with "Self-provisioned Fiber (with Special Construction)"
model_data_wdummies = model_data_wdummies[model_data_wdummies.connect_type != "Self-provisioned Fiber (with Special Construction)"]
## take out rows with "Lit Fiber (with Special Construction)"
model_data_wdummies = model_data_wdummies[model_data_wdummies.connect_type != "Lit Fiber (with Special Construction)"]

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connect_type,prefix='conntyp')],axis=1)
model_data_wdummies.drop('connect_type',axis=1,inplace=True)
model_data_wdummies.shape


# ### Connect Category

# In[51]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.connect_category,prefix='conncat')],axis=1)
model_data_wdummies.drop('connect_category',axis=1,inplace=True)
model_data_wdummies.shape


# ### States

# In[52]:

model_data_wdummies = pd.concat([model_data_wdummies,                                  pd.get_dummies(model_data_wdummies.postal_cd,prefix='st')],axis=1)
model_data_wdummies.drop('postal_cd',axis=1,inplace=True)
model_data_wdummies.shape


# ### Type of Product and Connection Used By (Don't exist in the new dataset anymore)

# Just assign the Type of Product Dummies

# In[53]:

#model_data_wdummies = pd.concat([model_data_wdummies, \
#                                 pd.get_dummies(model_data_wdummies.type_of_product,prefix='top')],axis=1)
#model_data_wdummies.drop('type_of_product',axis=1,inplace=True)
#model_data_wdummies.shape

#model_data_wdummies = pd.concat([model_data_wdummies, \
#                                 pd.get_dummies(model_data_wdummies.connection_used_by,prefix='cub')],axis=1)
#model_data_wdummies.drop('connection_used_by',axis=1,inplace=True)
#model_data_wdummies.shape


# -----

# ## Cleaning - Bools

# Convert these fields to to True/False

# ### Many Fields

# In[54]:

yn_fields = ['based_on_state_master_contract','pricing_confidentiality',
             'based_on_multiple_award_schedule','was_fcc_form470_posted',
             'includes_voluntary_extensions']

yn_map = {'Yes':True,'No':False}
for f in yn_fields:
    model_data_wdummies.loc[:,f] = model_data_wdummies[f].map(yn_map)
    model_data_wdummies.drop(f, axis=1, inplace=True)


# In[55]:

model_data_wdummies.head()


# **Review Summary**

# In[56]:

s1, s1s = color_code_summary(model_data_wdummies)


# In[57]:

s1s


# -------

# # Conform Future Data to the 2016 Data 

# ## Load in the Final Modeling Columns That Include all Dummies

# In[58]:

final_modeling_columns = pickle.load(open('model_data_versions/final_modeling_columns.pkl', 'rb'))


# In[59]:

print "In the 2016 modeling data we had {0} columns, we currently have {1} columns. "    .format(len(final_modeling_columns),model_data_wdummies.shape[1])
## Need to make sure the columns match


# ----

# ## Drop Columns and Rows for Data That Did Not Exist in 2016

# **Which Columns Are Not Present**

# In[60]:

diff_from_2016 = set(final_modeling_columns) - set(model_data_wdummies.columns.tolist())
diff_in_current_year = set(model_data_wdummies.columns.tolist()) - set(final_modeling_columns)


# In[61]:

print "These are the columns present in 2016 but not current year:"
print diff_from_2016
print ' '
print '*'*10
print 'These are the columns present in the current year but not in 2016:'
print diff_in_current_year
print ' '
print 'Also need to drop from both:', to_drop_in_2016


# **Notes**
# 
# **Connection Types:**
# 
# It makes sense why "T-4" and "T-5" connection types don't show up in 2016: there are only a few cases total (5) and none show up in the clean subset of the 2016 data. DROP FROM 2017
# 
# Same with "OC-768", only 1 in 2017. DROP FROM 2017
# 
# "Self-provisioned Fiber (with Special Construction)" doesn't look like it existed in 2016. We should maybe consolidate it with "Dark Fiber" in 2017, or remove those line items entirely. REMOVE ROWS FROM 2017
# 
# "Lit Fiber (with Special Construction)" also doesn't seem to appear in 2016. Most likely either all special construction projects were included under the higher-level categories (Dark or Lit Fiber) or didn't exist at all. REMOVE ROWS FROM 2017
# 
# "N/A" should be consolidated with "UNKNOWN". DONE.
# 
# 
# **Service Provider Dummys:**
# 
# Represent the rest of the columns, fine to take them out.

# ## Delete New Columns (Not in 2016 Data )

# In[62]:

print model_data_wdummies.shape
to_remove_from_2017 = list(diff_in_current_year)
to_remove_from_2017.append('num_open_flags')
print to_remove_from_2017
for item in to_remove_from_2017:
    del model_data_wdummies[item]
print model_data_wdummies.shape


# In[63]:

#diff_from_2016 = set(final_modeling_columns) - set(model_data_wdummies.columns.tolist())
diff_in_current_year = set(model_data_wdummies.columns.tolist()) - set(final_modeling_columns)
print diff_in_current_year


# ## Delete Select Columns in 2016 (Not in 2017 Data )

# In[64]:

data2016 = pd.read_csv('model_data_versions/model_data_output_pristine.csv')


# In[65]:

to_remove_from_2016 = ['application_type', 'num_recipients', 'num_open_flags']

print data2016.shape
for item in to_remove_from_2016:
    del data2016[item]
print data2016.shape


# In[66]:

final_modeling_columns = data2016.columns.tolist()


# In[67]:

with open('model_data_versions/final_modeling_columns.pkl','w') as f:
    pickle.dump(data2016.columns.tolist(),f)


# In[68]:

data2016.to_csv('model_data_versions/model_data_output_pristine.csv', index=False, float_format='%.3f')


# ## Create Empty Columns For Data That Does Not Exist in Current Year

# In[69]:

diff_from_2016.remove('cl_connect_category') ## DO NOT CREATE CL_CONNECT_CATEGORY !! --> We don't have that info. 
## also take out the columns we ended up removing completely from 2016 above
diff_from_2016.remove('application_type')
diff_from_2016.remove('num_recipients')
print diff_from_2016

for col in diff_from_2016:
    model_data_wdummies[col] = 0
print model_data_wdummies.shape


# ### Make Sure the Columns Are in the Matching Order as 2016 Data

# In[70]:

model_data_wdummies = model_data_wdummies[[i for i in final_modeling_columns if i != 'cl_connect_category']]


# In[71]:

model_data_wdummies.shape


# ## Drop Anything Else with an NA

# In[72]:

print model_data_wdummies.shape
final_model_data = model_data_wdummies.dropna()
final_model_data.shape


# In[73]:

final_model_data.to_csv('model_data_versions/featurized_2017_data.csv', index=False, float_format='%.3f')


# --------------

# # Verify The Datasets Match (Optional) '
# 
# This is more of a sanity check section. 

# In[74]:

#data2016 = pd.read_csv('model_data_versions/model_data_output_pristine.csv')


# In[75]:

data2016.drop('cl_connect_category', axis=1, inplace=True)


# In[76]:

data2016.shape


# In[77]:

final_model_data.shape


# **Review**
# 
# Just looking to make sure the data looks similar - comparing one 2016 row to a 2017 row.

# In[78]:

pd.concat([pd.DataFrame(final_model_data.ix[0],columns=['2017']),pd.DataFrame(data2016.ix[0],columns=['2016'])],axis=1)


# **Note**: In python `0` and `False` are equal and `1` and `True` are equal - So some differences in those columns are acceptable.

# **Example (Adrianna Delete if you want)**

# In[79]:

#print 0 == False
#print 1 == True
#print final_model_data.frn_complete[1:10]


# ----

# In[ ]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Featurizer_A_Main_2016_Data.ipynb', 'ESH_Featurizer_A_Main_2016_Data.py', main)


# # End

# -------
