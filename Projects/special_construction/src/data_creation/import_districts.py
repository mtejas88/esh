import sys
sys.path.insert(0, '../../data_creation/reg')

import psycopg2
from pandas import DataFrame

import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
cur = conn.cursor()
cur.execute("select * from districts_for_sc_reg;")
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
districts_for_sc_reg = DataFrame( rows, columns=names)
cur.close()
conn.close()

districts_for_sc_reg.round(2)
districts_for_sc_reg.to_csv('../../../data/interim/reg/districts_for_sc_reg.csv')

districts_for_sc_reg_clean = districts_for_sc_reg.loc[districts_for_sc_reg['exclude_from_ia_analysis'] == False]
districts_for_sc_reg_clean = districts_for_sc_reg_clean.loc[districts_for_sc_reg_clean['exclude_from_ia_cost_analysis'] == False]
districts_for_sc_reg_clean.to_csv('../../../data/interim/reg/districts_for_sc_reg_clean.csv')
