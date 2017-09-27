import psycopg2
import csv
from pandas import DataFrame, concat, read_csv, merge
 
import os
##from dotenv import load_dotenv, find_dotenv
##load_dotenv(find_dotenv())
HOST = os.environ.get("P_HOST")
USER = os.environ.get("P_USER")
PASSWORD = os.environ.get("P_PASSWORD")
DB = os.environ.get("P_DB")


csv_data = read_csv('/home/sat/sat_r_programs/funding_the_gap_2017/data/processed/state_metrics_tableau.csv', index_col=0, header=0)

print csv_data.iloc[0,]

myConnection = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, database=DB, port=5432)
cursor = myConnection.cursor()


cursor.execute("delete from  bus_intel.ftg;")


for index, row in csv_data.iterrows():

	cursor.execute("INSERT INTO bus_intel.ftg (district_postal_cd,methodology,value,cut,numbers)"\
                "VALUES (%s,%s,%s,%s,%s)",
               (row['district_postal_cd'],row['methodology'],row['value'],row['cut'],row['numbers']))


cursor.close()
myConnection.commit()
myConnection.close()

print "CSV data imported"
