
# coding: utf-8

# ![title](DataKind_orange_small.png)

# --------

# # TITLE: ESH Data 2016 --> 2017 Comparison
# 
# # Summary
# Just a quick check if 2017 data is similar to 2016 data - does not examine the changes in column values present in the 2017 data. We go into some of that in `ESH_Featurizer_B_Future_Data.ipynb` 

# ------

# In[89]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ------

# # Import Libraries

# In[90]:

import os
import psycopg2
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import math
import re
from collections import Counter
pd.set_option("display.max_columns",101)
pd.set_option("display.max_rows",151)
get_ipython().magic(u'matplotlib inline')


# -------

# # Load and Set up the Data 

# Establishing the PostgreSQL connection for PRIS2016

# In[91]:

HOST = os.environ.get("HOST_PRIS2016")
USER = os.environ.get("USER_PRIS2016")
PASSWORD = os.environ.get("PASSWORD_PRIS2016")
DB = os.environ.get("DB_PRIS2016")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# FRN Line Items (2016, Pristine)

# In[92]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw2016 = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[93]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata2016 = pd.DataFrame(rows, columns=names)


# Establishing the PostgreSQL connection for ONYX

# In[94]:

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# Clean Line Items (2016)

# In[95]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Establishing the PostgreSQL connection for PRIS2017

# In[96]:

HOST = os.environ.get("HOST_PRIS2017")
USER = os.environ.get("USER_PRIS2017")
PASSWORD = os.environ.get("PASSWORD_PRIS2017")
DB = os.environ.get("DB_PRIS2017")

conn = psycopg2.connect(host=HOST, user=USER, password=PASSWORD, dbname=DB)
cur = conn.cursor()


# FRN Line Items (2017, Pristine)

# In[97]:

cur.execute("select * from public.esh_line_items where funding_year=2017")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw2017 = pd.DataFrame(rows, columns=names)


# In[98]:

## in 2017, the open_flags are in a different dataset
cur.execute("select flaggable_id, count(label) as num_open_flags, array_agg(label) as open_flag_labels             from public.flags where funding_year=2017 and flaggable_type='LineItem'            and status='open' group by flaggable_id")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
rawflags2017 = pd.DataFrame(rows, columns=names)
rawflags2017.head(5)


# Metadata for Raw Line Items (2017)

# In[100]:

cur.execute("select * from fy2017.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata2017 = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[101]:

#raw2016 = pd.read_csv('LocalLargeFiles/fy2016_frn_line_items.csv', low_memory=False)
#metadata2016 = pd.read_csv('LocalLargeFiles/fy2016_frns.csv', low_memory=False)
#raw2017 = pd.read_csv('LocalLargeFiles/fy2017_frn_line_items', low_memory=False)
#metadata2017 = pd.read_csv('LocalLargeFiles/fy2017_frns', low_memory=False)
#clean = pd.read_csv('LocalLargeFiles/fy2016_line_items.csv', low_memory=False)


# -----

# # Basic Summary

# In[102]:

print 'Raw 2016'
print raw2016.describe()
print 'Shape', raw2016.shape
print 'Metadata Shape', metadata2016.shape
print ' '
print 'Raw 2017'
print raw2017.describe()
print 'Shape', raw2017.shape
print 'Shape', metadata2017.shape


# ------

# # Format Data

# Combine the metadata and frns

# In[103]:

## 2016
## merge in columns that don't exist already in metadata
uniq_cols= ['frn']+list(set(metadata2016.columns.tolist()) - set(raw2016.columns.tolist()))
mg_raw2016 = pd.merge(raw2016, metadata2016[uniq_cols], on='frn', how='left')
print mg_raw2016.shape


# In[107]:

## 2017
## combine flag info with raw2017, merge flaggable_id with id
raw2017 = pd.merge(raw2017, rawflags2017, left_on='id', right_on='flaggable_id', how='left')
raw2017.frn_complete = raw2017.frn_complete.astype(str)

## create the FRN id from the FRN_complete id
frn_list = []
for row in raw2017.frn_complete:
    if row != "Unknown":
        try:
            frn_list.append(int(re.split(r"\.\s*", row)[0]))
        except:
            frn_list.append(None)
    else:
        frn_list.append(None)

raw2017['frn'] = frn_list

## merge in columns that don't exist already in metadata
uniq_cols= ['frn']+list(set(metadata2017.columns.tolist()) - set(raw2017.columns.tolist()))
mg_raw2017 = pd.merge(raw2017, metadata2017[uniq_cols], on='frn', how='left')
print mg_raw2017.shape


# ------

# # Compare Columns

# **Compare all columns at once**

# In[112]:

print len(set(mg_raw2016.columns) & set(mg_raw2017.columns)) , 'shared columns'
print ' '
print len(set(mg_raw2016.columns) - set(mg_raw2017.columns)),set(mg_raw2016.columns) - set(mg_raw2017.columns), 'unshared'
print ' '
print len(set(mg_raw2017.columns) - set(mg_raw2016.columns)),set(mg_raw2017.columns) - set(mg_raw2016.columns), 'unshared'


# **Just the Line Items First**

# In[111]:

#print len(set(raw2016.columns) & set(raw2017.columns)) , 'shared columns'
#print len(set(raw2016.columns) - set(raw2017.columns)),set(raw2016.columns) - set(raw2017.columns), 'unshared'
#print len(set(raw2017.columns) - set(raw2016.columns)),set(raw2017.columns) - set(raw2016.columns), 'unshared'


# So applicant_ben has been renamed to just "ben" in the 2017 data- **looking good so far.**

# **Compare Metadata**

# In[113]:

#print len(set(metadata2016.columns) & set(metadata2017.columns)) , 'shared columns'
#print ' '
#print 'Unshared - in 2016 but not 2017'
#print len(set(metadata2016.columns) - set(metadata2017.columns)),set(metadata2016.columns) - set(metadata2017.columns)
#print ' '
#print 'Unshared - in 2017 but not 2016'
#print len(set(metadata2017.columns) - set(metadata2016.columns)),set(metadata2017.columns) - set(metadata2016.columns), 'unshared 2017 -> 2016'


# Same change as above!

# In[114]:

mg_raw2016.head(2)


# In[118]:

mg_raw2017[[c for c in mg_raw2016.columns.tolist() if c not in          ['application_type', 'applicant_name', 'applicant_postal_cd',          'service_provider_name', 'service_category', 'bandwidth_in_original_units',          'open_tag_labels', 'num_recipients', 'exclude', 'applicant_ben']]].head(2)


# # Conclusion
# 
# Looks like this data is in the same format, or has been converted to the same format. I did not do a detailed datatype comparison but from some quick visual examination , data types and column contents look comparable. 
# 
# Will follow up with ESH about this on our next call.

# -------

# # End
