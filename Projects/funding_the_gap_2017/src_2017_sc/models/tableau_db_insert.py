import psycopg2
import csv
from pandas import DataFrame, concat, read_csv, merge
 
import os

HOST = os.environ.get("P_HOST")
USER = os.environ.get("P_USER")
PASSWORD = os.environ.get("P_PASSWORD")
DB = os.environ.get("P_DB")
GITHUB = os.environ.get("GITHUB")


state_metrics_tableau = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/state_metrics_tableau.csv', index_col=0, header=0)
#initial_results_2017 = read_csv(GITHUB+'/Projects/funding_the_gap_2017/data/processed/initial_results_2017.csv', index_col=0, header=0)

print state_metrics_tableau.iloc[0,]

myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
cursor = myConnection.cursor()


cursor.execute("delete from  bus_intel.ftg;")
#cursor.execute("delete from  bus_intel.ftg_model;")

#first tableau table
for index, row in state_metrics_tableau.iterrows():

	cursor.execute("INSERT INTO bus_intel.ftg (district_postal_cd,methodology,value,cut,numbers)"\
                "VALUES (%s,%s,%s,%s,%s)",
               (row['district_postal_cd'],row['methodology'],row['value'],row['cut'],row['numbers']))

#second tabeau table (predictions)
#for index, row in initial_results_2017.iterrows():

#	cursor.execute("INSERT INTO bus_intel.ftg_model (postal_cd,min_2017,max_2017,prediction,prediction_lwr,prediction_upr,approved_state)"\
#               "VALUES (%s,%s,%s,%s,%s,%s,%s)",
#               (row['postal_cd'],row['min_2017'],row['max_2017'],row['prediction'],row['prediction_lwr'],row['prediction_upr'],row['approved_state'])


cursor.close()
myConnection.commit()
myConnection.close()

print "CSV data imported"
