
# coding: utf-8

# In[1]:

import sys
sys.path.insert(0, '../../data_creation/reg')

import psycopg2
from pandas import DataFrame

import os

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
cur = conn.cursor()
#open sql file to run
queryfile=open('../../data_creation/districts_for_sc_reg.sql', 'r')
query = queryfile.read()
queryfile.close()
cur.execute(query)
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
districts_for_sc_reg = DataFrame( rows, columns=names)
cur.close()
conn.close()


districts_for_sc_reg.head()

districts_for_sc_reg.round(2)

if not os.path.exists(os.path.dirname('../../../data/interim/reg/')):
    try:
        os.makedirs(os.path.dirname('../../../data/interim/reg/'))
    except OSError as exc: # Guard against race condition
        if exc.errno != errno.EEXIST:
            raise

districts_for_sc_reg.to_csv('../../../data/interim/reg/districts_for_sc_reg.csv')

districts_for_sc_reg_clean = districts_for_sc_reg.loc[districts_for_sc_reg['exclude_from_ia_analysis'] == False]
districts_for_sc_reg_clean = districts_for_sc_reg_clean.loc[districts_for_sc_reg_clean['exclude_from_ia_cost_analysis'] == False]
districts_for_sc_reg_clean.to_csv('../../../data/interim/reg/districts_for_sc_reg_clean.csv')

#will run only if using ipython notebook
sys.path.append(os.path.abspath('/Users/sierra/Documents/ESH/ficher/General_Resources/common_functions'))
import __main__ as main
import ipynb_convert 
ipynb_convert.executeConvertNotebook('import_districts.ipynb','import_districts_qa.py',main)

