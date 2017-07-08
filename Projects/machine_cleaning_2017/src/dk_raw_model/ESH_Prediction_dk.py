
# coding: utf-8

# ![title](DataKind_orange_small.png)

# --------

# # TITLE: ESH Model Prediction 
# 
# # Summary
# Example of how to apply the saved or "Persistent" models to the 2017 dataset. 
# 
# **NOTE**: When using the `.predict` with a binary classifier it sets the cutoff threshold to .5, which may not be appropriate. Just an FYI - probably better to use the `predict_proba` which provides probabilities. 

# ------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ------

# # Import Libraries

# In[1]:

import sys
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pickle 

## SKLEARN Imports
from sklearn.datasets import load_iris
from sklearn.model_selection import cross_val_score, KFold, GridSearchCV
from sklearn.tree import DecisionTreeClassifier, export_graphviz
from sklearn.ensemble import AdaBoostClassifier, ExtraTreesClassifier,     GradientBoostingClassifier, RandomForestClassifier
from sklearn import preprocessing
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support,     roc_auc_score, roc_curve, auc, confusion_matrix, mean_squared_error
from sklearn.dummy import DummyClassifier
from sklearn.svm import SVC
from sklearn.multiclass import OneVsRestClassifier, OneVsOneClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.externals import joblib

get_ipython().magic(u'matplotlib inline')
pd.set_option('max_rows',200)
pd.set_option('max_columns',200)
from scipy import misc
import subprocess
from IPython.display import Image


# In[3]:

from modeling_helpers import *


# -------

# # Load and Set up the Data 
# 
# When applying the model data setup is just importing - we already formatted it in the `ESH_Featurizer_B_Future_Data.ipynb` notebook, and since we don't have response variable information (Y) we don't need to do those subsets. 

# **Class Encoder**

# In[4]:

class_encoder = joblib.load('model_versions/final_models/classes_encoder.pkl')


# In[5]:

class_lookup = dict(zip(list(class_encoder.transform(class_encoder.classes_)),list(class_encoder.classes_)))
pd.DataFrame(zip(list(class_encoder.classes_), list(class_encoder.transform(class_encoder.classes_))))


# ** Load the Model Data **

# In[6]:

data_path = 'model_data_versions/featurized_2017_data.csv'
md = pd.read_csv(data_path)
mcc_review = md.copy(deep=True)
ids = md.id
md = md.drop(['id','has_na_fill'],axis=1)


# --------

# # 1. General Multiclass Model 

# ## Load the Column Order List 

# In[7]:

with open('model_data_versions/final_models/modA_column_order.pkl', 'rb') as f:
    modA_col_order = pickle.load(f)


# In[8]:

md = md[modA_col_order]


# ## Load the Model

# In[9]:

modA_multiclass = joblib.load('model_data_versions/final_models/general_multiclass.pkl')


# In[10]:

modA_multiclass


# ------

# ## Predict Probability

# In[11]:

mcc_review['pred'] = modA_multiclass.predict(md)


# In[12]:

mcc_review['connect_category'] = mcc_review.pred.map(class_lookup)


# In[13]:

mcc_review[['id','pred','connect_category']]


# In[14]:

mcc_review.shape


# In[15]:

mcc_review.connect_category.value_counts()


# **Lets Create a Dataframe the will hold the Predictions and ID**

# In[16]:

mcc_prediction_df = mcc_review[['id','pred','connect_category']]


# -------

# ## Predict Probabilities

# Now we have a dataframe with the predicted label, the ID and the predicted probabilites for each class.

# In[17]:

pd.DataFrame(modA_multiclass.predict_proba(md),                                      columns=class_encoder.classes_)


# In[18]:

mcc_prediction_df = pd.concat([mcc_prediction_df,                               pd.DataFrame(modA_multiclass.predict_proba(md),                                      columns=class_encoder.classes_)],                              axis=1)


# In[19]:

mcc_prediction_df


# In[20]:

## write out the dataset
mcc_prediction_df.to_csv('model_data_versions/final_models/2017_predictions_June16_2017.csv', index=False)


# -------

# # 2. General Binary Lit Fiber Model 

# ## Predict

# In[ ]:

modA_binary_lit_fiber_model = joblib.load('model_data_versions/final_models/lit_fiber_binary_classifier.pkl')
modA_binary_lit_fiber_model


# In[ ]:

binary_lf_predictions = pd.DataFrame(zip(mcc_review.id.tolist(), pd.DataFrame(modA_binary_lit_fiber_model.predict_proba(md))[1]),              columns = ['id','lit_fiber_proba'])


# -------

# # 3. Difference Column Models 

# ## Load Data and Columns

# In[ ]:

col_diff_labels = os.listdir('model_data_versions/final_models/col_diff_models/')
col_diff_models = {}
for cd in col_diff_labels:
    col_diff_models[cd.split('.')[0]] = joblib.load('model_data_versions/final_models/col_diff_models/'+cd)


# **Make Sure we Loaded all the Models**

# In[ ]:

col_diff_models


# ## Predict Probabilities

# In[ ]:

col_diff_prediction_df = review[['id','pred']]
col_diff_prediction_df.is_copy=False
for cd in col_diff_labels:
    actual_label = cd.split('.')[0]
    col_diff_prediction_df[actual_label] = pd.DataFrame(col_diff_models[actual_label].predict_proba(md))[1]


# **Review **

# In[ ]:

col_diff_prediction_df.head()


# -----------

# # 4. Composite Model 

# ## Data Setup 

# In[ ]:

with open('model_data_versions/final_models/modC_composite_model_column_order.pkl', 'rb') as f:
    modC_composite_col_order = pickle.load(f)
print len(modC_composite_col_order)


# **Check What Columns Are Missing - I.e. Output of LF binary model and Diff Col Models **

# In[ ]:

missing_cols = list(set(modC_composite_col_order) - set(md.columns.tolist()))
print missing_cols


# **Build the DataFrame**

# In[ ]:

composite_model_md = md.copy(deep=True)


# In[ ]:

plf = pd.DataFrame(binary_lf_predictions.lit_fiber_proba)
plf.columns = ['plf']


# In[ ]:

diffcols = [u'diff_function',
       u'diff_download_speed_units', u'diff_total_cost',
       u'diff_application_number', u'diff_connect_type', u'diff_purpose',
       u'diff_download_speed']


# In[ ]:

diff_col_values = {}
for cd in col_diff_labels:
    col_label =  'prb_' + '_'.join(cd.split('_')[0:-1])
    diff_col_values[col_label] = col_diff_prediction_df[cd.split('.')[0]]


# In[ ]:

diff_cols_df = pd.DataFrame(diff_col_values)


# In[ ]:

composite_md = pd.concat([md, plf, diff_cols_df],axis=1)


# In[ ]:

composite_md.shape


# In[ ]:

composite_md = composite_md[modC_composite_col_order]


# ## Predict 

# In[ ]:

modC_composite_model = joblib.load('model_data_versions/final_models/composite_multiclass.pkl')
modC_composite_model


# In[ ]:

pd.DataFrame(modC_composite_model.predict_proba(composite_md),columns=class_encoder.classes_)


# -----

# **Convert this notebook to a python file**

# In[2]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Prediction_dk.ipynb', 'ESH_Prediction_dk.py', main)


# # End
