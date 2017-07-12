
# coding: utf-8

# ![title](DataKind_orange_small.png)
# 

# ---------

# # TITLE: Education Superhighway - Binary Column Change Classifiers

# # Summary
# In this File we will:
# 1. Finalize the Data Setup for modeling
# 2. Create a series of models for predicting if some major columns changed from Raw --> Clean
# 3. Export Probability of Change for major columns for use in Composite Model
# 4. Export Models for Resuse

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
from sklearn.model_selection import cross_val_score, KFold, GridSearchCV
from sklearn.tree import DecisionTreeClassifier, export_graphviz
from sklearn.ensemble import AdaBoostClassifier, ExtraTreesClassifier,     GradientBoostingClassifier, RandomForestClassifier
from sklearn import preprocessing
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support,     roc_auc_score, roc_curve, auc, confusion_matrix
from sklearn.dummy import DummyClassifier
from sklearn.svm import SVC
from sklearn.multiclass import OneVsRestClassifier, OneVsOneClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.base import clone


get_ipython().magic(u'matplotlib inline')
pd.set_option('max_rows',200)
from scipy import misc
import subprocess
from IPython.display import Image


# # Helper Functions

# In[14]:

from modeling_helpers import *


# In[15]:

def run_cv_on_model(base_model, xdata,ydata,classes, kfold_n = 5, binary=False):
    all_fit = clone(base_model)
    current_fit = clone(base_model)
    
    xdata = xdata.as_matrix()
    kfold = KFold(n_splits=kfold_n, shuffle=True)
    test_out = []
    train_out = []
    
    for train, test in kfold.split(xdata):
        model = current_fit.fit(xdata[train], ydata[train])
        test_score = model.score(xdata[test], ydata[test])
        train_score = model.score(xdata[train],ydata[train])
        test_out.append(test_score)
        train_out.append(train_score)
    

    
    if not binary:
        precision, precision_all, recall, recall_all, accuracy,                 accuracy_all = classifier_scores(ydata, model.predict(xdata))
    
        pra = {'precision':precision, 
               'precision_all':precision_all,
               'recall': recall, 
               'recall_all':recall_all, 
               'accuracy': accuracy, 
               'accuracy_all': accuracy_all}
        
        fpr, tpr, roc_auc = compute_multiclass_roc_auc(ydata,model.predict_proba(xdata),classes)
        ftr = {'fpr':fpr,
               'tpr': tpr, 
               'roc_auc': roc_auc}

    else:
        fpr, tpr, roc_auc, precision, recall, accuracy = binary_classifier_scores(ydata,                                                                                  model.predict(xdata),                                                            pd.DataFrame(model.predict_proba(xdata))[1])
        pra = {'precision':precision, 
               'recall': recall, 
               'accuracy': accuracy
              }
        ftr = {'fpr':fpr,
               'tpr': tpr, 
               'roc_auc': roc_auc}
        
    cm = df_confusion_matrix(ydata, model.predict(xdata),classes)
    print model.score(xdata,ydata)
    return model, test_out, train_out, pra, ftr, cm, all_fit.fit(xdata, ydata)
    


# 
# -------

# # Data Setup 

# ** Load Change Data **

# In[16]:

changes = pd.read_csv('local_data/changecount_Apr27_17.csv')


# In[17]:

diffcols = [u'diff_function',
       u'diff_download_speed_units', u'diff_total_cost',
       u'diff_application_number', u'diff_connect_type', u'diff_purpose',
       u'diff_download_speed']


# In[18]:

changes[diffcols].sum()


# ** Load Validation Set **

# In[19]:

#validation_set = pd.read_csv('local_data/esh_validation_sample.csv')
validation_set = pd.read_csv('data/esh_validation_sample.csv')


# **Load Model Data **

# In[20]:

data_path = 'data/model_data_output_DK_handoff.csv'
md = pd.read_csv(data_path)

## Segment the Validation Set and 
validation_set = md[md.id.isin(validation_set.id)]
md = md[-md.id.isin(validation_set.id)]

print md.shape
md = md.merge(changes[['id']+diffcols], on='id',how='left')
## Do the Necessary Drops on the X 
X = md.drop(['id','cl_connect_category','has_na_fill'],axis=1)
X = X.drop(diffcols, axis=1)
print X.shape

## We are using different Y's in this one - so we won't hardcode it here. 


# In[9]:

with open('model_versions/final_models/modA_column_order.pkl', 'rb') as f:
    modA_col_order = pickle.load(f)


# ** Setup Validation Set Data **

# In[9]:

validation_set = validation_set.merge(changes[['id']+diffcols], on='id',how='left')
vld_X = validation_set.drop(['id','cl_connect_category','has_na_fill'],axis=1)
vld_X = vld_X.drop(diffcols, axis=1)


# In[10]:

import time
current_time = (time.strftime('%h_%d_%y_t%H_%M'))


# -----------
# 
# ----------

# # Model Search on Binary Change or Not
# 
# Using only RandomForest model to cut down on run time - and that seems to work best on these datasets.

# In[11]:

diff_models_search = {}

models = [('RandomForestClassifier',RandomForestClassifier(n_estimators=20, 
                                 max_depth=10, \
                                 max_features=.50,\
                                 n_jobs=-1,\
                                 oob_score=False,
                                 class_weight='balanced_subsample'))
         ]

for d in diffcols:
    print 10*"#" + ' ' + d + ' Column Being Modeled: ' + "#"*10
    current_Y = md[d]
    for m in models:
        print 10*'*' +''+ m[0] + '' + 10*'*'

        fit_m,te,ta,pra,ftr,cm,model_fit_all = run_cv_on_model(m[1],X,current_Y,["0",'1'],binary=True)
        diff_models_search[d] = {d:fit_m,'te':te,'ta':ta,'pra':pra,'ftr':ftr,'cm':cm,'model_fit_all':model_fit_all}
        print 'Train', np.array(ta).mean(), 'Test', np.array(te).mean()
        confusion_matrix_from_df(cm,'Result: '+m[0])
        plot_rocs(ftr['fpr'],ftr['tpr'],['1'])


    


# ------

# # Feature Importances

# In[12]:

ftr_imp_diff_models = {}
for k in diff_models_search:
    ftr_imp_diff_models[k] = get_feature_importances(diff_models_search[k]['model_fit_all'],X)
    plot_importance(ftr_imp_diff_models[k],k,40,(15,15))


# # Compare Training Score vs. Fit All Score vs. Validation Set Score

# In[13]:

for k in diffcols:
    print k, '-- training data fit:', round(diff_models_search[k][k].score(X,md[k]),4),         '-- All Data Fit', round(diff_models_search[k]['model_fit_all'].score(X,md[k]),4),        '-- Validation Set', round(diff_models_search[k]['model_fit_all'].score(vld_X,validation_set[k]),4)


# Validation scores look great - not too much lower than train or all scores - that is a very good sign. 

# **NOTE**: In the printed out table below the "model_spec" column shows Decision Tree, this is some sort of glitch, if you look at an individual value in the table cell it will say RandomForest 
# 
# `m3_summary.model_spec[0]` shows the correct thing - we know they are all RandomForests so leaving this for now, not sure where that glitch is coming from, also if you look at the dictionary object with all the data it shows up corrrectly (`diff_model_search`). 

# In[14]:

data_readme = """Difference Modeling - seeing if the we can predict the probability that columns will be altered"""
m3_summary = build_df_binary_results(diff_models_search,data_path,data_readme)
m3_summary.to_pickle('results/modB_difference_models_'+current_time)
m3_summary


# ------

# # Note on Grid Search

# DK did not conduct a grid search on these models just because of time constraints and because grid search did not significantly improve model performance in the other models developed. You could implement it though by copping over code from the primary modeling notebook and setting up a loop over each of the columns. It will take a couple of hours to run depending on the number of parameteres you include. 

# ---------

# # Predict 

# In[15]:

out_df_validation = validation_set.copy(deep=True)
out_df_main = md.copy(deep=True)


# In[16]:

for k in diffcols:
    print k, round(diff_models_search[k][k].score(X,md[k]),3),        round(diff_models_search[k]['model_fit_all'].score(X,md[k]),3),        round(diff_models_search[k]['model_fit_all'].score(vld_X,validation_set[k]),3)
    out_df_main['prb_' + k] = pd.DataFrame(diff_models_search[k]['model_fit_all'].predict_proba(X))[1]
    out_df_validation['prb_' + k] = pd.DataFrame(diff_models_search[k]['model_fit_all'].predict_proba(vld_X))[1]


# In[18]:

out_df_main.to_csv('results/change_probabilities_main_v1.csv',index=False)
out_df_validation.to_csv('results/change_probabilities_validation_v1.csv',index=False)


# In[19]:

print md.shape
print out_df_main.shape
print validation_set.shape
print out_df_validation.shape


# # Export Models for Resuse 

# In[20]:

from sklearn.externals import joblib


# In[21]:

for k in diffcols:
    joblib.dump(diff_models_search[k]['model_fit_all'], 'final_models/col_diff_models/' + k + '_model.pkl') 


# # Example Use of the Saved Model 

# In[22]:

joblib.load('final_models/col_diff_models/diff_function_model.pkl').score(vld_X, validation_set.diff_function)


# ---------

# **Convert this notebook to a python file**

# In[2]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Modeling_B_Binary_Column_Difference_Prediction_dk.ipynb', 'ESH_Modeling_B_Binary_Column_Difference_Prediction_dk.py', main)


# # End

# --------
# 
# ---------
# 
# ---------
