
# coding: utf-8

# ![title](DataKind_orange_small.png)

# --------

# # TITLE: ESH Data 2016 --> 2017 Comparison
# 
# # Summary
# Just a quick check if 2017 data is similar to 2016 data - does not examine the changes in column values present in the 2017 data. We go into some of that in `ESH_Featurizer_B_Future_Data.ipynb` 

# ------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ------

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
raw2016 = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[5]:

cur.execute("select * from fy2016.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata2016 = pd.DataFrame(rows, columns=names)


# Clean Line Items (2016)

# In[6]:

cur.execute("select * from fy2016.line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
clean = pd.DataFrame(rows, columns=names)


# Raw FRN Line Items (2017)

# In[7]:

cur.execute("select * from fy2017.frn_line_items")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
raw2017 = pd.DataFrame(rows, columns=names)


# Metadata for Raw Line Items (2016)

# In[8]:

cur.execute("select * from fy2017.frns")
names = [x[0] for x in cur.description]
rows = cur.fetchall()
metadata2017 = pd.DataFrame(rows, columns=names)


# Loading Dataset from Local Files (Optional)

# In[9]:

#raw2016 = pd.read_csv('LocalLargeFiles/fy2016_frn_line_items.csv', low_memory=False)
#metadata2016 = pd.read_csv('LocalLargeFiles/fy2016_frns.csv', low_memory=False)

#raw2017 = pd.read_csv('LocalLargeFiles/fy2017_frn_line_items', low_memory=False)
#metadata2017 = pd.read_csv('LocalLargeFiles/fy2017_frns', low_memory=False)

#clean = pd.read_csv('LocalLargeFiles/fy2016_line_items.csv', low_memory=False)


# -----

# # Basic Summary

# In[9]:

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

# # Compare Columns

# **Just the Line Items First**

# In[10]:

print len(set(raw2016.columns) & set(raw2017.columns)) , 'shared columns'
print len(set(raw2016.columns) - set(raw2017.columns)),set(raw2016.columns) - set(raw2017.columns), 'unshared'
print len(set(raw2017.columns) - set(raw2016.columns)),set(raw2017.columns) - set(raw2016.columns), 'unshared'


# So applicant_ben has been renamed to just "ben" in the 2017 data- **looking good so far.**

# In[11]:

print len(set(metadata2016.columns) & set(metadata2017.columns)) , 'shared columns'

print ' '
print 'Unshared - in 2016 but not 2017'
print len(set(metadata2016.columns) - set(metadata2017.columns)),set(metadata2016.columns) - set(metadata2017.columns)
print ' '
print 'Unshared - in 2017 but not 2016'
print len(set(metadata2017.columns) - set(metadata2016.columns)),set(metadata2017.columns) - set(metadata2016.columns), 'unshared 2017 -> 2016'


# Same change as above!

# In[12]:

raw2016.head(2)


# In[13]:

raw2017[[c for c in raw2016.columns.tolist() if c != 'applicant_ben' ]].head(2)


# # Conclusion
# 
# Looks like this data is in the same format, or has been converted to the same format. I did not do a detailed datatype comparison but from some quick visual examination , data types and column contents look comparable. 
# 
# Will follow up with ESH about this on our next call.

# -------

# # End
