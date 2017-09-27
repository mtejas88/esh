##imports and definitions
#import packages
import psycopg2
from pandas import DataFrame, concat

#import environment variables
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
HOST_ONYX = os.environ.get("HOST_ONYX")
USER_ONYX = os.environ.get("USER_ONYX")
PASSWORD_ONYX = os.environ.get("PASSWORD_ONYX")
DB_ONYX = os.environ.get("DB_ONYX")
PORT_ONYX = os.environ.get("PORT_ONYX")
#HOST_CRIMSON = os.environ.get("HOST_CRIMSON")
#USER_CRIMSON = os.environ.get("USER_CRIMSON")
#PASSWORD_CRIMSON = os.environ.get("PASSWORD_CRIMSON")
#DB_CRIMSON = os.environ.get("DB_CRIMSON")
#PORT_CRIMSON = os.environ.get("PORT_CRIMSON")
GITHUB = os.environ.get("GITHUB")

#import classes
os.chdir(GITHUB+'/Projects/streamlined_app/src') 
from query import getData

##connect to onyx and save list of FRNs into pandas dataframe
#open connection to onyx
myConnection = psycopg2.connect( host=HOST_ONYX, user=USER_ONYX, password=PASSWORD_ONYX, database=DB_ONYX, port=PORT_ONYX)

#pull 2016 FRNs from DB
frns_2016 = getData( myConnection, 'frns_2016.sql')
print("2016 FRNs pulled from database")

#pull 2017 FRNs from DB
frns_2017 = getData( myConnection, 'frns_2017.sql')
print("2017 FRNs pulled from database")

#close connection to onyx
myConnection.close()

##connect to onyx and save list of applications into pandas dataframe
#open connection to onyx
myConnection = psycopg2.connect( host=HOST_ONYX, user=USER_ONYX, password=PASSWORD_ONYX, database=DB_ONYX, port=PORT_ONYX)

#pull 2016 applications from DB
applications_2016 = getData( myConnection, 'applications_2016_contd.sql')
print("2016 applications pulled from database")

#pull 2017 applications from DB
applications_2017 = getData( myConnection, 'applications_2017_contd.sql')
print("2017 applications pulled from database")

#close connection to onyx
myConnection.close()

##connect to crimson and save list of applications into pandas dataframe
#open connection to crimson
#myConnection = psycopg2.connect( host=HOST_CRIMSON , user=USER_CRIMSON , password=PASSWORD_CRIMSON , database=DB_CRIMSON , port=PORT_CRIMSON)

#pull 2015 applications from DB
#applications_2015 = getData( myConnection, 'applications_2015_contd.sql')
#print("2016 applications pulled from database")

#close connection to crimson
#myConnection.close()

##save
#source of raw data
os.chdir(GITHUB+'/Projects/streamlined_app/data/raw') 

#save files
frns_2016.to_csv('frns_2016.csv')
frns_2017.to_csv('frns_2017.csv')
print("2016 and 2017 FRNs saved")

#applications_2015.to_csv('applications_2015_contd.csv')
applications_2016.to_csv('applications_2016_contd.csv')
applications_2017.to_csv('applications_2017_contd.csv')
print("2016 and 2017 applications saved")

