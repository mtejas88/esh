
# coding: utf-8

# ![title](DataKind_orange_small.png)
# 

# ---------

# # TITLE: Education Superhighway Primary Modeling Notebook

# # Summary
# In this File we will:
# 1. Finalize the Data Setup for modeling
# 2. Create a multiclass model of Connect Category
# 3. Create a binary classification model of Lit Fiber
# 4. Conduct Grid Search (Hyperparamter Search) for Multiclass and Binary Model
# 5. Export Binary Lit Fiber Predictions for Use in Composite Model
# 6. Export Models for Resuse
# 

# ------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

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


get_ipython().magic(u'matplotlib inline')
pd.set_option('max_rows',200)
pd.set_option('max_columns',200)
from scipy import misc
import subprocess
from IPython.display import Image


# ## Modeling Helpers
# There are a bunch of functions that we use in the modeling process that have been moved to a separate `.py` script to clean up the layout of the notebook. Please reference that file to understand some of the functions. 

# In[3]:

from modeling_helpers import *


# # Helper Functions

# In[4]:

def run_cv_on_model(base_model,xdata,ydata,classes, binary=False):
    """Run cross validation on model, takes a sklearn model object, 
    X data, Y data, the classes we are modeling and whether we are modeling binary (True/False)"""
    xdata = xdata.as_matrix()
    kfold = KFold(n_splits=3, shuffle=True)
    test_out = []
    train_out = []
    counter = 0
    
    for train, test in kfold.split(xdata):
        counter += 1
        print counter
        model = base_model.fit(xdata[train], ydata[train])
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
    
    mse = mean_squared_error(ydata, model.predict(xdata))
    cm = df_confusion_matrix(ydata, model.predict(xdata),classes)
    return model, test_out, train_out, pra, ftr, cm, mse
    


# 
# -------

# # Data Setup 

# ** DO NOT UNCOMMENT BELOW - This is the hold out set we will verify model perfomanace on at the end of the process. **

# In[5]:

#validation_set = md.sample(8000).to_csv('data/esh_validation_sample_June16_2017.csv',index=False)


# In[6]:

validation_set = pd.read_csv('data/esh_validation_sample.csv')


# In[7]:

validation_set.cl_connect_category.value_counts()


# ### Modeling Data Set up

# In[8]:

data_path = 'data/model_data_output_June16_2017.csv'


# In[9]:

md = pd.read_csv(data_path)

validation_set = md[md.id.isin(validation_set.id)]
md = md[-md.id.isin(validation_set.id)]
print md.shape

#########################
#### GET THE X DATA #####
## Multiclass Data Setup
## Dropping the "has_na_fill" field - could use as a feature if the pattern of NA filling is the same in 
## (continued) 2017 as in 2016
X = md.drop(['id','cl_connect_category','has_na_fill'],axis=1) ## Drop some cols from the X data
Y = md.cl_connect_category


#### Endocde the Multiclass Labels ####
## SKLEARN requires numerical features so convert Connect Category to Numerical fields
le = preprocessing.LabelEncoder()
le.fit(md.cl_connect_category)

## Binary Lit Fiber Y
Y_justLF = np.array([1 if i == 'Lit Fiber' else 0 for i in Y])


## Multiclass Y 
Y = le.transform(md.cl_connect_category)



print X.shape


# ### Validation Data Setup

# In[10]:

## Validation X needs to match the Modeling X in format
vld_X = validation_set
vld_Y = validation_set.cl_connect_category
vld_X = vld_X.drop(['id','cl_connect_category','has_na_fill'],axis=1)
vld_Y_justLF= np.array([1 if i == 'Lit Fiber' else 0 for i in vld_Y])
vld_Y = le.transform(vld_Y)


# --------
# 
# ------
# 
# ------

# # M1 - Multiclass Classification Model (MCC) on Connect Category
# 
# 

# ** For Reference - What the Actual Values Per Group Are **

# In[11]:

md.cl_connect_category.value_counts()


# ----

# ## MCC - Search on Models

# In the Search on model block you can try different models in one place and see results. We generally apply some models and see what has promise, we use either default parameters on common ones. Reference SKLEARN docs for the various parameters. 

# In[12]:

model_search = {}

## Below you can uncomment some of the speciifc models, or ever add other models to the list and 
## Each model in the list will be tested
models = [
#     ('LogisticRegression',LogisticRegression(),
         ('RandomForestClassifier',RandomForestClassifier(n_estimators=100, \
                                 max_depth=10, \
                                 max_features=.33,\
                                 class_weight = 'balanced',
                                 n_jobs=-1,\
                                 oob_score=False)),
          ('DecisionTreeClassifier',DecisionTreeClassifier(max_depth=8)),
#           ('ExtraTreesClassifier',ExtraTreesClassifier(n_estimators=100, max_depth=8,class_weight='balanced')),
#           ('GradientBoostingClassifier',GradientBoostingClassifier())
         ]

for m in models:
    print 10*'*' +''+ m[0] + '' + 10*'*'

    fit_m,te,ta,pra,ftr,cm,mse = run_cv_on_model(m[1],X,Y,le.classes_)
    model_search[m[0]] = {m[0]:fit_m,'te':te,'ta':ta,'pra':pra,'ftr':ftr,'cm':cm,'mse':mse}
    print 'Train', np.array(ta).mean(), 'Test', np.array(te).mean(), 'MSE', mse
    confusion_matrix_from_df(cm,'Result :' + m[0])
    plot_rocs(ftr['fpr'],ftr['tpr'],le.classes_)



# ------

# ## MCC - Important Features

# In[13]:

ftr_imp_all = {}
for k in model_search:
    try:
        ftr_imp_all[k] = get_feature_importances(model_search[k][k],X)
        plot_importance(ftr_imp_all[k],k,40,(15,15))
    except AttributeError:
        print k, 'Does not have important features.'


# In[14]:

import time
current_time = (time.strftime('%h_%d_%y_t%H_%M'))


# ### MCC - Print and Export Model Summary

# In[15]:

## In the data_readme field you can write a comment that will be written to a column in the dataframe,
## so you could include any changes you made, or when you did it etc, just for record keeping

data_readme = """Final Run Before June 19th Presentation"""
m1_summary = build_df_multiclas_results(model_search,data_path,data_readme)
m1_summary.to_pickle('model_versions/modA_MCC_model_'+current_time)
m1_summary


# -----------
# 
# ----------
# 
# ----------

# # M2 - Binary Classification Model on Lit Fiber (BLF)

# ## BLF - Search on Models 

# In[16]:

binary_model_search = {}
models = [('RandomForestClassifier',RandomForestClassifier(n_estimators=100, 
                                 max_depth=8, \
                                 max_features=.50,\
                                 n_jobs=-1,\
                                 oob_score=False)),
#           ('DecisionTreeClassifier',DecisionTreeClassifier(max_depth=8)),
#           ('ExtraTreesClassifier',ExtraTreesClassifier(n_estimators=100, max_depth=8)),
#           ('AdaBoostClassifier',AdaBoostClassifier(n_estimators=100)),
#           ('GradientBoostingClassifier',GradientBoostingClassifier(max_depth=8, n_estimators=500))
         ]

for m in models:
    print 10*'*' +''+ m[0] + '' + 10*'*'

    fit_m,te,ta,pra,ftr,cm,mse = run_cv_on_model(m[1],X,Y_justLF,['0','1'],binary=True)
    
    binary_model_search[m[0]] = {m[0]:fit_m,'te':te,'ta':ta,'pra':pra,'ftr':ftr,'cm':cm,'mse':mse}
    print 'Train', np.array(ta).mean(), 'Test', np.array(te).mean(), 'MSE:', mse
    confusion_matrix_from_df(cm,'Result: '+m[0])
    plot_rocs(ftr['fpr'],ftr['tpr'],['1'])
    


# ------

# ## BLF - Important Features

# In[17]:

ftr_imp_LFbin = {}
for k in binary_model_search:
    ftr_imp_LFbin[k] = get_feature_importances(binary_model_search[k][k],X)
    plot_importance(ftr_imp_LFbin[k],k,40,(15,15))


# ### BLF - Print and Export Model Summary

# In[18]:

data_readme = """Final Binary Lit Fiber Model before June 19th Presentation"""
m3_summary = build_df_binary_results(binary_model_search,data_path,data_readme)
m3_summary.to_pickle('model_versions/modA_BLF_model_'+current_time)
m3_summary


# --------
# 
# ---------
# 
# ---------

# # Grid Search on Select Models

# ## Grid Search Helper Functions

# In[19]:

def gs_result_to_df(gs_result):
    model_ranking = pd.DataFrame(gs_result)
    model_ranking.columns = ['Model','BestParams','Classifier',
                             'Accuracy_Train','Accuracy_Test','Accuracy_All',
                             'Precision_Train','Precision_Test','Precision_All',
                             'Recall_Train','Recall_Test','Recall_All',
                             'AUC_Train','AUC_Test','AUC_All',
                             'Dummy_Train','Dummy_Test','Dummy_All',
                             'FPR_Train','TPR_Train',
                             'FPR_Test','TPR_Test',
                             'FPR_All','TPR_All', 'MSE_Train','MSE_Test','MSE_All','cm']
    return model_ranking

def gs_mc_result_to_df(gs_result):
    model_ranking = pd.DataFrame(gs_result)

    model_ranking.columns = ['Model','BestParams','Classifier',
                             'Accuracy_Train','Accuracy_Test','Accuracy_All',
                             'OVR_Accuracy_Train','OVR_Accuracy_Test','OVR_Accuracy_All',
                             'Precision_Train','Precision_Test','Precision_All',
                             'OVR_Precision_Train','OVR_Precision_Test','OVR_Precision_All',
                             'Recall_Train','Recall_Test','Recall_All',
                             'OVR_Recall_Train','OVR_Recall_Test','OVR_Recall_All',
                             'AUC_Train','AUC_Test','AUC_All',
    #                          'OVR__AUC_Train','OVR_AUC_Test','OVR_AUC_All',
                             'Dummy_Train','Dummy_Test','Dummy_All',
                             'FPR_Train','TPR_Train',
                             'FPR_Test','TPR_Test',
                             'FPR_All','TPR_All','cm']
    return model_ranking

def gs_result_to_cm(gs_result,title):
    return confusion_matrix_from_df(gs_result[0][-1],title)

def gs_binary_result_to_roc(gs_result):
    plot_rocs(gs_result[0][-6],gs_result[0][-5],['1'])

def gs_mc_result_to_roc(gs_result, classes):
    plot_rocs(gs_result[0][-3],gs_result[0][-2],classes)


# ------

# ## GS-M1 -  Multiclass Connect Category Model (MCC)
# 
# ### MCC Grid Search

# When doing multiclass optimization there are a couple of different optimization parameters. Some will focus on overal accuracy some will focus on class accuracy, etc. 
# 
# See: http://scikit-learn.org/stable/modules/model_evaluation.html
# 
# Some options are: 'f1_micro', 'f1_macro','accuracy'
# 
# You can play with these to see if the results change - especially if you have a certain goal in mind. 

# In[20]:

multiclass_optimization_parameter = 'f1_micro'


# In[21]:

def grid_search_multiclass(X_all, y_all, classifiers,classes,mop = multiclass_optimization_parameter):
    
    # Runs grid search on given list of classifiers and parameters dictionary
    best_params = []
    feature_importances = {}
    X_train, X_test, y_train, y_test = train_test_split(X_all, y_all, test_size=0.33)
    
    # Dummy Classifier results
    dc = OneVsRestClassifier(DummyClassifier(strategy='most_frequent'),n_jobs=-1)
    dc.fit(X_train, y_train)
    dummy_acc_train = accuracy_score(y_train, dc.predict(X_train))
    dummy_acc_test = accuracy_score(y_test, dc.predict(X_test))
    dummy_acc_all = accuracy_score(y_all, dc.predict(X_all))
    
    for clf in classifiers:    
        model = clf[0]
        print '*** ' + model + ' ***'        
        classifier = GridSearchCV(clf[1], clf[2],n_jobs=-1,scoring=mop,verbose=2)            

        classifier.fit(X_train,y_train)
        params = str(classifier.best_params_)

        fpr, tpr, precision, recall, accuracy, accuracy_all, precision_all, recall_all, roc_auc, roc_auc_all = ({} for i in range(10))
        
        for sets in ['all','train','test']:
            X = eval('X_' + sets)
            y = eval('y_' + sets)
            y_pred = classifier.predict(X)
            y_pred_proba = classifier.predict_proba(X)
            precision[sets], precision_all[sets], recall[sets], recall_all[sets], accuracy[sets], accuracy_all[sets] = classifier_scores(y, y_pred)
            fpr[sets], tpr[sets], roc_auc[sets] = compute_multiclass_roc_auc(y, y_pred_proba, classes)
            
        cm = df_confusion_matrix(y_all, classifier.predict(X_all),classes)
        best_params.append([model, params, classifier, 
                            accuracy['train'], accuracy['test'], accuracy['all'],
                            accuracy_all['train'], accuracy_all['test'], accuracy_all['all'],
                            precision['train'], precision['test'], precision['all'],
                            precision_all['train'], precision_all['test'], precision_all['all'],
                            recall['train'], recall['test'], recall['all'],
                            recall_all['train'], recall_all['test'], recall_all['all'],
                            roc_auc['train'], roc_auc['test'], roc_auc['all'],
                            # roc_auc_all['train'], roc_auc_all['test'], roc_auc_all['all'],
                            dummy_acc_train, dummy_acc_test, dummy_acc_all,
                            fpr['train'], tpr['train'],
                            fpr['test'], tpr['test'],
                            fpr['all'], tpr['all'],cm])
        
    return best_params


# ### MCC - Grid Search Parameters 

# We can pick different parameters to do a search on - the more parameters the longer it will take. Review the SKLEARN docs to see the different parameters each model has. 

# In[22]:

current_mc_classifier = [('RandomForestClassifier',
                RandomForestClassifier(),
                {'max_depth':[10],'n_estimators': [50,100,300],'max_features': [ .33,.5],\
                 'class_weight':['balanced']
                }
               )]


# In[23]:

MCC_Model_GS = grid_search_multiclass(X,Y,current_mc_classifier,le.classes_)


# ### MCC - Result Summary

# In[24]:

gs_mc_result_to_df(MCC_Model_GS)


# ### MCC - Best Parameters

# In[25]:

MCC_Model_GS[0][1]


# ### MCC - Confusion Matrix

# In[26]:

gs_result_to_cm(MCC_Model_GS,'Full Basic RF Model')


# ### MCC - ROC Curves

# In[27]:

gs_mc_result_to_roc(MCC_Model_GS, le.classes_)


# -------

# ** Now run the Grid Search on the Binary Lit Fiber Models **

# -------------

# ## GS-M2 Binary Lit Fiber Model (BLF)

# ### BLF Grid Search

# In[28]:

def grid_search_binary(X_all, y_all, classifiers,classes):
    
    # Runs grid search on given list of classifiers and parameters dictionary
    best_params = []
    feature_importances = {}
    X_train, X_test, y_train, y_test = train_test_split(X_all, y_all, test_size=0.33)
    
    # Dummy Classifier results
    dc = OneVsRestClassifier(DummyClassifier(strategy='most_frequent'),n_jobs=-1)
    dc.fit(X_train, y_train)
    dummy_acc_train = accuracy_score(y_train, dc.predict(X_train))
    dummy_acc_test = accuracy_score(y_test, dc.predict(X_test))
    dummy_acc_all = accuracy_score(y_all, dc.predict(X_all))

    
    classifier = GridSearchCV(classifiers[1], classifiers[2], n_jobs=-1,scoring='f1',verbose=2)       
    classifier.fit(X_train,y_train)
    params = str(classifier.best_params_)
    print params    
    
    fpr, tpr, precision, recall, accuracy, roc_auc, mse = ({} for i in range(7))

    for sets in ['all','train','test']:
        X = eval('X_' + sets)
        y = eval('y_' + sets)
        print sets, X.shape
        y_pred = classifier.predict(X)
        y_pred_proba = classifier.predict_proba(X)
        
        
        fpr[sets], tpr[sets], roc_auc[sets], precision[sets], recall[sets], accuracy[sets] =                 binary_classifier_scores(y, y_pred,pd.DataFrame(y_pred_proba)[1])
        mse[sets] = mean_squared_error(y,y_pred)
        
    cm = df_confusion_matrix(y_all, classifier.predict(X_all),classes)
    best_params.append([classifiers[0], params, classifier, 
                        accuracy['train'], accuracy['test'], accuracy['all'],
                        precision['train'], precision['test'], precision['all'],
                        recall['train'], recall['test'], recall['all'],
                        roc_auc['train'], roc_auc['test'], roc_auc['all'],
                        dummy_acc_train, dummy_acc_test, dummy_acc_all,
                        fpr['train'], tpr['train'],
                        fpr['test'], tpr['test'],
                        fpr['all'], tpr['all'],
                        mse['train'],mse['test'],mse['all'],cm])
        
    return best_params


# In[29]:

current_classifier = ('RandomForestClassifier',
                RandomForestClassifier(),
                {'max_depth':[10],'n_estimators': [50,100],'max_features': [ .33,.5],\
                 'class_weight':['balanced']
                }
               )


# In[30]:

Binary_LitFiber_Model_GS = grid_search_binary(X,Y_justLF,current_classifier,['0','1'])


# ### BLF Results Summary

# In[31]:

gs_result_to_df(Binary_LitFiber_Model_GS)


# ### BLF Best Parameters

# In[32]:

Binary_LitFiber_Model_GS[0][1]


# ### BLF Confusion Matrix

# In[33]:

gs_result_to_cm(Binary_LitFiber_Model_GS,'Grid Search LF Binary')


# ### BLF ROC Curve

# In[34]:

gs_binary_result_to_roc(Binary_LitFiber_Model_GS)


# --------
# 
# -------

# # Finalize Models - Retrain with All Data 

# ### F-MCC - Build Model with Best Parameters on All Data

# Once we are comfortable with the performance of the model we retrain it on all the data (train + test) and then apply that final model to the validation set. If you felt you were having issues with overfitting we may just apply the model that was fit on the train set. But since we are doing really well on the overfitting we will train the model on that train+test set. 

# In[35]:

MCC_Predict_Model = RandomForestClassifier(**eval(MCC_Model_GS[0][1]))
MCC_Predict_Model.fit(X, Y)
MCC_Predict_Model.score(X,Y)


# ### F-MCC - All Data Score on the Validation Set

# In[36]:

print MCC_Predict_Model.score(vld_X, vld_Y)


# ### F-MCC - All Data Review Important Features

# In[37]:

gs_mc_importances = get_feature_importances(MCC_Predict_Model,X)
plot_importance(gs_mc_importances,'Random Forest Multiclass',40,(15,15))


# ### F-MCC - All Data Review Confusion Matrix

# In[38]:

mc_all_review = pd.DataFrame(zip(Y,MCC_Predict_Model.predict(X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(mc_all_review.y, mc_all_review.y_pred,le.classes_))


# ### F-MCC - Validation Set - Confusion Matrix 

# In[39]:

mc_review = pd.DataFrame(zip(vld_Y,MCC_Predict_Model.predict(vld_X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(mc_review.y, mc_review.y_pred,le.classes_))


# ---------

# ------------

# ------

# ## F-BLF  - Build Model with Best Parameters on All Data

# Once we are comfortable with the performance of the model we retrain it on all the data (train + test) and then apply that final model to the validation set. If you felt you were having issues with overfitting we may just apply the model that was fit on the train set. But since we are doing really well on the overfitting we will train the model on that train+test set. 

# In[40]:

binaryLF_Predict_Model = RandomForestClassifier(**eval(Binary_LitFiber_Model_GS[0][1]))
binaryLF_Predict_Model.fit(X,Y_justLF)
binaryLF_Predict_Model.score(X, Y_justLF)


# ### F-BLF -  All Data Score on the Validation Set

# In[41]:

binaryLF_Predict_Model.score(vld_X, vld_Y_justLF)


# ### F-BLF - All Data Review Important Features 

# In[42]:

gs_bin_importances = get_feature_importances(binaryLF_Predict_Model,X)
plot_importance(gs_bin_importances,'Random Forest Binary',40,(15,15))


# ### F-BLF - All Data Review Confusion Matrix

# In[43]:

bin_all_review = pd.DataFrame(zip(Y_justLF,binaryLF_Predict_Model.predict(X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(bin_all_review.y, bin_all_review.y_pred,['0','1']))


# ### F-BLF - Validation Set - Confusion Matrix

# In[44]:

bin_VLD_review = pd.DataFrame(zip(vld_Y_justLF,binaryLF_Predict_Model.predict(vld_X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(bin_VLD_review.y, bin_VLD_review.y_pred,['0','1']))


# ### F-BLF - Output to Binary Lit Fiber Predictions to File
# 
# We export these predictions for use in the "Composite Model".

# ** Export the Train+Test Probabilities **

# In[45]:

predict_probabilites = pd.DataFrame(binaryLF_Predict_Model.predict_proba(X))
predict_probabilites.columns = ['false','plf']
predict_probabilites.index = md['id']
predict_probabilites.reset_index().to_csv('data/June16_lit_fiber_probabilities.csv',index=False)


# **Export the Validation Set Probabilities**

# In[46]:

vld_predict_probabilites = pd.DataFrame(binaryLF_Predict_Model.predict_proba(vld_X))
vld_predict_probabilites.columns = ['false','plf']
vld_predict_probabilites.index = validation_set['id']
vld_predict_probabilites.reset_index().to_csv('data/June16_validation_set_lit_fiber_probabilities.csv'                                              ,index=False)


# -------

# ---------

# -------

# # Export Models 

# We will export the models to a pickle format. We use the joblib library as it is recommended for sklearn. <br> See the reference on  <a href="http://scikit-learn.org/stable/modules/model_persistence.html">Model Persistence.</a>
# 
# By saving the model in this format we can apply it other years data without having to retrain each time. 

# In[47]:

from sklearn.externals import joblib


# In[48]:

joblib.dump(MCC_Predict_Model, 'model_versions/final_models/general_multiclass.pkl') 


# In[49]:

joblib.dump(binaryLF_Predict_Model, 'model_versions/final_models/lit_fiber_binary_classifier.pkl')


# ### Export the Class Encoder Too

# In[50]:

joblib.dump(le, 'model_versions/final_models/classes_encoder.pkl')


# **Export the X Data Columns to a List**
# We want to make sure we preserve the order so we can make sure the columns are in the correct order when using these models in production environment with new data.

# In[51]:

with open('model_versions/final_models/modA_column_order.pkl', 'wb') as f:
    pickle.dump(list(X.columns), f)


# --------------

# **Convert this notebook to a python file**

# In[2]:

sys.path.append(os.path.abspath('/Users/adriannaesh/Documents/ESH-Code/ficher/General_Resources/common_functions/'))
import __main__ as main
import ipynb_convert
ipynb_convert.executeConvertNotebook('ESH_Modeling_A_Primary_Modeling_dk.ipynb', 'ESH_Modeling_A_Primary_Modeling_dk.py', main)


# # End 
