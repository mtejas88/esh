
# coding: utf-8

# ![title](DataKind_orange_small.png)
# 

# ---------

# # TITLE: Education Super Highway Modeling Composite Model
# 
# ## Primary Differences
# 
# **Testing**: Using the Lit Fiber Probability as a feature. <br>
# **Outcome**: Some minor model improvement - not enormous - may keep in for now. 

# # Summary
# In this File we will:
# 1. Finalize the Data Setup for modeling
# 2. Create a series of models for Connect Category - using the outputs of models developed in Modeling Notebook A & B.
# 3. Create a model that first predicts whether item is Lit Fiber, removes those items then apply a Multiclass model on the remaining data. 
# 3. Export Models for Reuse
# 

# ------

# In[1]:

get_ipython().run_cell_magic(u'javascript', u'', u"$.getScript('https://kmahelona.github.io/ipython_notebook_goodies/ipython_notebook_toc.js')")


# <h1 id="tocheading">Table of Contents</h1>
# <div id="toc"></div>

# ------

# # Import Libraries

# In[13]:

from sklearn.model_selection import cross_val_score, KFold, GridSearchCV
from sklearn.tree import DecisionTreeClassifier, export_graphviz
from sklearn.ensemble import AdaBoostClassifier, ExtraTreesClassifier,     GradientBoostingClassifier, RandomForestClassifier
from sklearn import preprocessing
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support,     roc_auc_score, roc_curve, auc, confusion_matrix, mean_squared_error
from sklearn.dummy import DummyClassifier
from sklearn.multiclass import OneVsRestClassifier, OneVsOneClassifier
from sklearn.linear_model import LogisticRegression


# In[14]:

from modeling_helpers import *


# In[15]:

get_ipython().magic(u'matplotlib inline')
pd.set_option('max_rows',200)
from scipy import misc
import subprocess
from IPython.display import Image


# # Helper Functions

# In[16]:

def run_cv_on_model(base_model,xdata,ydata,classes, binary=False):
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
    


# In[17]:


def visualize_tree(tree, name, feature_names):
    """Create tree png using graphviz.

    Args
    ----
    tree -- scikit-learn DecsisionTree.
    feature_names -- list of feature names.
    """
    with open(name+".dot", 'w') as f:
        export_graphviz(tree, out_file=f,
                        feature_names=feature_names)

    command = ["dot", "-Tpng", name+".dot", "-o", name+".png"]
    try:
        subprocess.check_call(command)
    except:
        print 'Fail'
    return Image(name+".png")


# 
# -------

# # Data Setup 

# **Difference Columns - True/False **

# In[18]:

diffcols = [u'diff_function',
       u'diff_download_speed_units', u'diff_total_cost',
       u'diff_application_number', u'diff_connect_type', u'diff_purpose',
       u'diff_download_speed']
prb_diffcols = ['prb_i' for i in diffcols]


# ** Validation Set **

# In[19]:

validation_set = pd.read_csv('results/change_probabilities_validation_v1.csv')


# ** Lit Fiber Probabilities** Generated in `ESH_Modeling_A_Primary_Modeling`

# In[20]:

litfib_prob = pd.read_csv('local_data/May9_lit_fiber_probabilities.csv')
validation_set_litfib_prob = pd.read_csv('local_data/May9_validation_set_lit_fiber_probabilities.csv')
print litfib_prob.shape
print validation_set_litfib_prob.shape


# **Main Modeling Data + Change Probabilities **

# In[21]:

data_path = 'results/change_probabilities_main_v1.csv'


# -------

# # Modeling Data Setup 

# ** Modeling Data (Train + Test)**

# In[26]:

md = pd.read_csv(data_path)

## The line below is redundant cause validation set isnt in the data
## But nice to have it explicit there so we remember that 
md = md[~md.id.isin(validation_set.id)]  

md = md.merge(litfib_prob[['id','plf']],on='id')
print md.shape
raw = md.copy(deep=True)

## Regular
X = md.drop(['id','cl_connect_category','has_na_fill'],axis=1)

if 'Unnamed: 0' in md.columns.tolist():
    X.drop(['Unnamed: 0'],axis=1,inplace=True)
X = X.drop(diffcols,axis=1)
Y = md.cl_connect_category


## Endocde the Labels
le = preprocessing.LabelEncoder()
le.fit(md.cl_connect_category)

## Get Y
Y = le.transform(md.cl_connect_category)
print X.shape


# ### Validation Data Setup

# In[27]:

vld_X = validation_set.copy(deep=True)
vld_X = vld_X.merge(validation_set_litfib_prob[['id','plf']],on='id')
vld_Y = validation_set.cl_connect_category
vld_X = vld_X.drop(['id','cl_connect_category','has_na_fill'],axis=1)
vld_X = vld_X.drop(diffcols, axis=1)
if 'Unnamed: 0' in vld_X.columns.tolist():
    vld_X.drop(['Unnamed: 0'],axis=1,inplace=True)
vld_Y = le.transform(vld_Y)
print vld_X.shape


# ---------
# 
# ---------

# # Composite Model (COMP)
# 
# Multiclass Model on Connect Category Using the P(Lit Fiber) and P(Column Changes)
# 

# ## COMP - Searching on Models

# In[28]:

model_search = {}
models = [
#     ('LogisticRegression',LogisticRegression(n_jobs=-1)),
         ('RandomForestClassifier',RandomForestClassifier(n_estimators=100, \
                                 max_depth=10, \
                                 max_features=.33,\
                                 class_weight = 'balanced',
                                 n_jobs=-1,\
                                 oob_score=False)),
          ('DecisionTreeClassifier',DecisionTreeClassifier(max_depth=6,min_samples_leaf=2)),
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



# ### COMP - Visualize Decision Tree
# 
# **NOTE** There are some required packages needed to display this - that can be difficult to get installed. I have kept it here or reference. I think the main packages are graphviz and pydot. 

# In[29]:

visualize_tree(model_search['DecisionTreeClassifier']['DecisionTreeClassifier'],'results/composite_tree',X.columns)


# ### COMP - Important Features

# In[30]:

ftr_imp_all = {}
for k in model_search:
    try:
        ftr_imp_all[k] = get_feature_importances(model_search[k][k],X)
        plot_importance(ftr_imp_all[k],k,40,(15,15))
    except AttributeError:
        print k, 'Does not have important features.'


# In[31]:

import time
current_time = (time.strftime('%h_%d_%y_t%H_%M'))


# In[32]:

data_readme = """Model with the probability that the fields will be diffed"""
m1_summary = build_df_multiclas_results(model_search,data_path,data_readme)
m1_summary.to_pickle('results/modC_composite_model_'+current_time)
m1_summary


# # COMP - Finalize Model Retrain With All Data

# In[33]:

composite_predict = m1_summary.ix[1].model_spec.fit(X, Y)


# ## COMP - All Data Score on Validation Set

# In[34]:

print 'All score', composite_predict.score(X,Y)
print 'Validation score', composite_predict.score(vld_X, vld_Y)


# ## COMP - All Data Review Important Features

# In[35]:

comp_mc_importances = get_feature_importances(composite_predict,X)
plot_importance(comp_mc_importances,'Random Forest Multiclass Composite',40,(15,15))


# ## COMP - All Data Review Confusion Matrix 

# In[36]:

comp_all_review = pd.DataFrame(zip(Y,composite_predict.predict(X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(comp_all_review.y, comp_all_review.y_pred,le.classes_))


# ## COMP - Validation Set Confusion Matrix

# In[37]:

composite_VLD_review = pd.DataFrame(zip(vld_Y,composite_predict.predict(vld_X)),columns=['y','y_pred'])
confusion_matrix_from_df(df_confusion_matrix(composite_VLD_review.y, composite_VLD_review.y_pred,le.classes_),                        plot_title='Composite Model - Validation Set')


# # COMP - Export Composite Model 

# In[38]:

from sklearn.externals import joblib
joblib.dump(composite_predict, 'final_models/composite_multiclass.pkl') 


# ## COMP - Export the Composite Model Column Order 

# In[39]:

with open('final_models/modC_composite_model_column_order.pkl', 'wb') as f:
    pickle.dump(list(X.columns), f)


# -----------
# 
# ----------

# # Subset Model (SUBS)
# 

# ## Strategy
# 
# ** First Remove those sites where P(Lit Fiber is Highest) ** <br>
# ** Then MultiClass Classifier on the Remaining Sites **
# 
# **Note**: This model is complicated to implement and doesn't have superior performance - DK is including it in case it makes sense to be used in the future, and to highlight another method that can be tested. But we will not export a final model. If ESH is interested in creating a production version of this in their workflow - look at how we have exported other models.
# 
# The idea behind this model is to identify those rows that have a very high probability of being lit fiber, then removing them and applying a MultiClass model on the rest of the data. We need to determine a good cutoff percentage to select those Lit Fiber rows. So first we will look at the distribution of predictions. We are using the probability from the binary lit fiber model. 

# ## SUBS - Train the Model 

# ### Identify Probability Cutoff

# **Create A new DataFrame for this review X & Y Data **

# In[40]:

review = pd.concat([X,pd.DataFrame(Y,columns=['cl_connect_category'])],axis=1)


# **Plot the Probability of Being Lit Fiber where It is Lit Fiber and where it is NOT Lit Fiber**

# In[41]:

fig, ax = plt.subplots(figsize=(16, 6))
sns.distplot(review[(review.cl_connect_category == 5)].plf,kde_kws={'label':'Lit Fiber=True'}, ax=ax)
sns.distplot(review[(review.cl_connect_category != 5)].plf, kde_kws={'label':'Lit Fiber=False'},ax=ax)
ax.set(xlabel='Probability of Lit Fiber')


# **Create A Bunch of Probability Values from 0->1**

# In[42]:

pvals = np.linspace(0.0,1.0,num=45)


# In[43]:

pvals


# **Iterate over the pvals and identify how many Correct Lit Fiber and Incorrect Lit Fiber Predictions we Get for Each Value**

# In[44]:

correct=[]
incorrect =[]
for p in pvals:
    incorrect.append(review[((review.cl_connect_category != 5) & (review.plf > p))].shape[0])
    correct.append(review[(review.cl_connect_category == 5) & (review.plf > p)].shape[0])


# ** Construct Data Frame and Review **

# In the chart below we see that from about .83-1 very few observations are predicted to be Lit Fiber, then we see a large jump in the True line at about .82. The black line shows the difference between Correctly Predicted Lit Fiber and Incorrectly Predicted Lit Fiber. 

# In[45]:

res = pd.DataFrame(zip(pvals, correct, incorrect))
res.columns = ['p','true','false']
res['rdiff'] = res.true - res.false

fig, ax = plt.subplots(figsize=(15, 5))
sns.set_style("darkgrid")
ax.plot(res.p,res.true,label='True')
ax.plot(res.p,res.false,label='False')
ax.plot(res.p,res.rdiff,label='Difference',color='black',linestyle='-.')

plt.legend(prop=dict(size=12))


# **Context**: At about the 81% mark we see a big chunk of the lit fiber being assigned and a smaller amount of misclassification. We will use that as our current cutoff

# In[46]:

res.tail(10)


# ------

# ### SUBS -  Subset Data 

# ** We Select the Cutoff to be .81% and Subset the Data **

# In[50]:

cutoff = .81
review_subset = review[review.plf < cutoff]
print 'Rest of the Data with Identified Lit Fiber Removed', review_subset.shape

lit_fiber_subset = review[review.plf >=cutoff]
print 'Identified Lit Fiber', lit_fiber_subset.shape
print  'Total Data', review_subset.shape[0] +  lit_fiber_subset.shape[0]
print review.shape


# ### SUBS - Modeling on the Subset (With High Probability Lit Fiber Removed)

# In[51]:

subset_X = review_subset.drop('cl_connect_category',axis=1)
subset_Y = review_subset.cl_connect_category


# In[52]:

subset_model_search = {}
models = [
#     ('LogisticRegression',LogisticRegression(n_jobs=-1)),
         ('RandomForestClassifier',RandomForestClassifier(n_estimators=100, \
                                 max_depth=10, \
                                 max_features=.33,\
                                 class_weight = 'balanced',
                                 n_jobs=-1,\
                                 oob_score=False)),
#           ('DecisionTreeClassifier',DecisionTreeClassifier(max_depth=8,min_samples_leaf=2)),
#           ('ExtraTreesClassifier',ExtraTreesClassifier(n_estimators=100, max_depth=8,class_weight='balanced')),
#           ('GradientBoostingClassifier',GradientBoostingClassifier())
         ]

for m in models:
    print 10*'*' +''+ m[0] + '' + 10*'*'

    fit_m,te,ta,pra,ftr,cm,mse = run_cv_on_model(m[1],subset_X,subset_Y.as_matrix(),le.classes_)
    subset_model_search[m[0]] = {m[0]:fit_m,'te':te,'ta':ta,'pra':pra,'ftr':ftr,'cm':cm,'mse':mse}
    print 'Train', np.array(ta).mean(), 'Test', np.array(te).mean(), 'MSE', mse
    confusion_matrix_from_df(cm,'Result :' + m[0])
    plot_rocs(ftr['fpr'],ftr['tpr'],le.classes_)


# ### SUBS -  Important Features

# In[53]:

subset_mc_importances = get_feature_importances(subset_model_search['RandomForestClassifier']['RandomForestClassifier'],X)
plot_importance(subset_mc_importances,'Random Forest Multiclass Subset Model',40,(15,15))


# ----------

# ## SUBS - Retrain on All Data (Train + Test) and Review Final Results 

# **Predict on the Subset with the Model Fitted to All Data **

# In[54]:

final_review_X = subset_X.copy(deep=True)
final_subset_model = subset_model_search['RandomForestClassifier']['RandomForestClassifier'].fit(subset_X,subset_Y)
final_review_X['y_pred'] = final_subset_model.predict(subset_X)
final_review_X['y'] = subset_Y


# **Format the Lit Fiber Subset **

# In[55]:

lit_fiber_subset.is_copy = False
lit_fiber_subset['y_pred'] = 5
lit_fiber_subset['y'] = lit_fiber_subset.cl_connect_category
lit_fiber_subset = lit_fiber_subset.drop('cl_connect_category',axis=1)


# ### SUBS - Combine the 2 Subsets - Review the Confusion Matrix

# In[56]:

final_review = lit_fiber_subset.append(final_review_X)


# In[57]:

confusion_matrix_from_df(df_confusion_matrix(final_review.y, final_review.y_pred, le.classes_))


# --------

# ## SUBS - Review on Validation Set 

# ### Subset the Data

# In[58]:

cutoff = .81
vld_review = pd.concat([vld_X,pd.DataFrame(vld_Y,columns=['cl_connect_category'])],axis=1)
vld_subset = vld_review[vld_review.plf < cutoff]
print 'Rest of the Data with Identified Lit Fiber Removed', review_subset.shape

vld_lit_fiber_subset = vld_review[vld_review.plf >=cutoff]
print 'Identified Lit Fiber', vld_lit_fiber_subset.shape
print  'Total Data', vld_subset.shape[0] +  vld_lit_fiber_subset.shape[0]
print vld_review.shape


# In[59]:

vld_subset_X = vld_subset.drop('cl_connect_category',axis=1)
vld_subset_Y = vld_subset.cl_connect_category


# ** Predict on the Subset Validation Data  **

# In[60]:

vld_final_review_X = vld_subset_X.copy(deep=True)
vld_final_review_X['y_pred'] = final_subset_model.predict(vld_subset_X)
vld_final_review_X['y'] = vld_subset_Y


# **Format the Lit Fiber Subset**

# In[61]:

vld_lit_fiber_subset.is_copy = False
vld_lit_fiber_subset['y_pred'] = 5
vld_lit_fiber_subset['y'] = vld_lit_fiber_subset.cl_connect_category
vld_lit_fiber_subset = vld_lit_fiber_subset.drop('cl_connect_category',axis=1)


# In[62]:

vld_final_review = vld_lit_fiber_subset.append(vld_final_review_X)


# In[63]:

confusion_matrix_from_df(df_confusion_matrix(vld_final_review.y, vld_final_review.y_pred, le.classes_),                         plot_title='Subset Model - Validation Set')


# The model has good performance but it is very similar to the validation set result from the basic Multiclass Classification model. Given the complexity involved in applying this model DK again thinks the basic Multiclass model estimated in `ESH_Modeling_A_Primary_Modeling` is the best the model.

# ------

# # END

# --------
# 
# ---------
# 
# ---------
