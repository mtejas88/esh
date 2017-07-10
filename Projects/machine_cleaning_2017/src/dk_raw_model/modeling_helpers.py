################################## 
## DataKind 2017 - Michael Dowd ##
################################## 


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pickle 
import sys
import subprocess
## SKLEARN Imports
from sklearn.model_selection import cross_val_score, KFold, GridSearchCV
from sklearn.tree import DecisionTreeClassifier, export_graphviz
from sklearn.ensemble import AdaBoostClassifier, ExtraTreesClassifier, \
    GradientBoostingClassifier, RandomForestClassifier
from sklearn import preprocessing
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_recall_fscore_support, \
    roc_auc_score, roc_curve, auc, confusion_matrix, mean_squared_error
from sklearn.dummy import DummyClassifier
from sklearn.multiclass import OneVsRestClassifier, OneVsOneClassifier
from sklearn.linear_model import LogisticRegression


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


def get_feature_importances(clf,X):
    '''
    returns feature importances
    '''
    importances = clf.feature_importances_
    indices = np.argsort(importances)[::-1]
    feat_importance = pd.DataFrame(X.columns, importances)    
    feat_importance.reset_index(inplace=True)
    feat_importance.columns = ['Importance','Feature']
    feat_importance.sort_values(by='Importance', axis=0, ascending=True, inplace=True)
    feat_importance.set_index('Feature',inplace=True)
    return feat_importance

def plot_rocs(fprs,tprs,classes,model_label='ROC Review'):
    """Plot the roc curves, frp=false positive rates, tprs = true positive rates, classes=classification classes,
    model_label=has default value but you can set your own label"""

    fig, ax = plt.subplots(figsize=(14, 10))

    sns.set_style("darkgrid")
    if len(classes) == 1:
        roc_df = pd.DataFrame(dict(false_positive_rate=fprs, true_positive_rate=tprs))
        auc_sc = auc(fprs,tprs)
        legend_entry = 'Binary' + ': (AUC={0})'.format(round(auc_sc,2))
        ax.plot(roc_df.false_positive_rate,roc_df.true_positive_rate,label=legend_entry)
    else:
        for c in classes:
                
            roc_df = pd.DataFrame(dict(false_positive_rate=fprs[c], true_positive_rate=tprs[c]))
            auc_sc = auc(fprs[c],tprs[c])
            legend_entry = c + ': (AUC={0})'.format(round(auc_sc,2))
            
            if c == 'Lit Fiber':
                ax.plot(roc_df.false_positive_rate,roc_df.true_positive_rate,\
                        label=legend_entry,color='yellow',\
                       linestyle='-.')
            else:
                ax.plot(roc_df.false_positive_rate,roc_df.true_positive_rate,label=legend_entry,\
                           linestyle='-')

    ax.plot(roc_df.false_positive_rate,roc_df.false_positive_rate,\
            linestyle='--',color='black',label='Reference')
    ax.plot()
    plt.suptitle(model_label)
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.legend(loc="lower right")
    plt.show()

def classifier_scores(y, pred):
    '''
    From y-true and y-predicted, returns classifier scores
    ''' 
    accuracy_all = accuracy_score(y, pred)
    precision_all, recall_all, f_score_all, _ = precision_recall_fscore_support(y, pred)
    precision, recall, accuracy = ({} for i in range(3))
    
    y = pd.get_dummies(pd.DataFrame(y))
    pred = pd.get_dummies(pd.DataFrame(pred))
    pred.columns = y.columns
    
    for i in y.columns.tolist():
        precision[i], recall[i], fscore, _ = precision_recall_fscore_support(y[i], pred[i])
        accuracy[i] = accuracy_score(y[i], pred[i])
        
    return precision, precision_all, recall, recall_all, accuracy, accuracy_all

def plot_importance(imp_df,model_label,imp_n=20, fsize = (15,7)):
    """Takes a dataframe of importances and plots them, 
    imp_n=Number of importances to show,fsize=Tuple of figure size"""
    data = imp_df.sort_values('Importance',ascending=False).head(imp_n).reset_index()
    fig, ax = plt.subplots(figsize=fsize)
    ax = sns.barplot(y="Feature", x="Importance", data=data)
    ax.set_title(model_label + ': Important Features')
    plt.xticks(rotation=0) 
    plt.show()

def binary_classifier_scores(y, pred, pred_prob):
    """ Creates scoring results for binary classifier"""
    accuracy = accuracy_score(y, np.round(pred, decimals=0))
    precision, recall, f_score, _ = precision_recall_fscore_support(y, np.round(pred, decimals=0))
    roc_auc = roc_auc_score(y, pred)
    fpr, tpr, _ = roc_curve(y, pred_prob)

    return fpr, tpr, roc_auc, precision, recall, accuracy

def compute_multiclass_roc_auc(y_test, y_score, classes):
    """Computes parameters needed for ROC Curve plot"""
    fpr = dict()
    tpr = dict()
    roc_auc = dict()
    y4roc = pd.get_dummies(y_test)
    y_score_4roc = pd.DataFrame(y_score)
    y4roc.columns = classes
    y_score_4roc.columns = classes
    for col in y4roc.columns:
        fpr[col], tpr[col], _ = roc_curve(y4roc[col], y_score_4roc[col])
        roc_auc[col] = auc(fpr[col], tpr[col])

    # Compute micro-average ROC curve and ROC area
    ylist = [y4roc[col].tolist() for col in y4roc.columns]
    ylist = [item for sublist in ylist for item in sublist]
    yscorelist = [y_score_4roc[col].tolist() for col in y_score_4roc.columns]
    yscorelist = [item for sublist in yscorelist for item in sublist]
    fpr["micro"], tpr["micro"], _ = roc_curve(ylist, yscorelist)
    roc_auc["micro"] = auc(fpr["micro"], tpr["micro"])
    
    return fpr, tpr, roc_auc

def df_confusion_matrix(y_raw, y_pred, classes):
    """Make a confusion matrix dataframe with error rates and correct rates"""
    a = pd.DataFrame(confusion_matrix(y_raw,y_pred))
    a.columns = classes
    a.index = classes
    a['correct_rate'] = pd.Series(np.diag(a), index=[a.index, a.columns]).values/a.sum(axis=1)
    a['error_rate'] = 1-a.correct_rate
    return a

def confusion_matrix_from_df(df,plot_title='Results'):
    """Make a heatmap confusion matrix from a dataframe confusion matrix table"""
    import seaborn as sns
    from matplotlib import gridspec

    sns.set(font_scale=1.2)
    data =df[df.columns[:-2]]
    labels = df[df.columns[:-2]]
    fig = plt.figure(figsize=(12, 8)) 
    plt.suptitle(plot_title)


    gs = gridspec.GridSpec(1, 2, width_ratios=[4, 1]) 
    ax0 = plt.subplot(gs[0])
    ax0.set_title('Confusion Matrix')

    
    ax1 = plt.subplot(gs[1])
    ax1.set_title('Correct & Error Rates')

    sns.heatmap(data, annot = labels, fmt = '',ax=ax0)
    sns.heatmap(df[df.columns[-2:]],annot=True, ax=ax1)
    plt.xticks(rotation=40) 
    ax0.set_xlabel('Predicted')
    ax0.set_ylabel('Actual')
    gs.tight_layout(fig, rect=[0, 0.1, 1, .95])  

def build_df_binary_results(model_dict,data_path,readme):
    """Build a dataframe from the model search dictionaries - For Binary Results"""

    cols = ['model_name','model_spec','acc_train_mean','acc_test_mean','acc_all'\
        ,'raw_train','raw_test','precision','recall','roc_auc','tpr','fpr','cm']
    L =[]
    for k in model_dict:
        data = model_dict[k]
        L.append([k, data[k], np.array(data['ta']).mean(), \
                  np.array(data['te']).mean(),data['pra']['accuracy'],\
                    data['ta'], data['te'], data['pra']['precision'], \
                  data['pra']['recall'], data['ftr']['roc_auc'],\
                    data['ftr']['tpr'],data['ftr']['fpr'],data['cm']])
    df = pd.DataFrame(L,columns=cols)
    df['data_ref'] = data_path
    df['readme'] = readme
    return df

def build_df_multiclas_results(model_dict,data_path,readme):
    """Build a dataframe from the model search dictionaries - For Multiclass Results"""
    cols = ['model_name','model_spec','acc_train_mean','acc_test_mean','acc_all'\
        ,'raw_train','raw_test','precision','recall','roc_auc_many','tpr','fpr','cm']
    L =[]
    for k in model_dict:
        data = model_dict[k]
        L.append([k, data[k], np.array(data['ta']).mean(),\
                  np.array(data['te']).mean(),data['pra']['accuracy_all'],\
                    data['ta'], data['te'], data['pra']['precision'], \
                  data['pra']['recall'], data['ftr']['roc_auc'],\
                    data['ftr']['tpr'],data['ftr']['fpr'],data['cm']])
    df = pd.DataFrame(L,columns=cols)
    df['data_ref'] = data_path
    df['readme'] = readme
    return df