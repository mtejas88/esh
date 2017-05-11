##import packages and connect to DB
import sys
import os
import psycopg2
import pandas as pd
import requests

HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

conn = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
cur = conn.cursor()

##districts table - ALL districts from 2016 districts_deluxe (esh_ids) and their lat/longs
queryfile=open('queries/districts.sql', 'r')
query = queryfile.read()
queryfile.close()
cur.execute(query)
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
districts = pd.DataFrame( rows, columns=names)

##schools table - ALL schools from fy2016.schools (esh_ids) and their lat/longs
queryfile=open('queries/schools.sql', 'r')
query = queryfile.read()
queryfile.close()
cur.execute(query)
names = [ x[0] for x in cur.description]
rows = cur.fetchall()
schools = pd.DataFrame( rows, columns=names)

##combine into one table with esh_ids
esh_ids=pd.concat([districts,schools],axis=0,ignore_index=True)
cur.close()
conn.close()

# class for getting the census block(s) from the api from a given set of lat/long coordinates. 
# Outputs a pandas dataframe
class getCensusBlock():

    def __init__(self, esh_id, lat, lon):
        self.esh_id = esh_id
        self.lat = lat
        self.lon = lon

    def censusAPIRequest(self):
        response = requests.get('http://data.fcc.gov/api/block/find?format=json&latitude='+self.lat+'&longitude='+self.lon+'&showall=true')
        block=''
        if response.json()['status'] == 'OK':
            try:
                if 'boundary' in str(response.json()['messages'][0]):
                    block = str(response.json()['Block']['intersection'])
                    blockdf=pd.DataFrame(eval(block))
                    blockdf['esh_id']=self.esh_id
                    blockdf['latitude']=self.lat
                    blockdf['longitude']=self.lon
                    blockdf = blockdf.ix[:, ['esh_id','latitude','longitude','FIPS']]
                    blockdf.columns=[['esh_id','latitude','longitude','BlockCode']]
            except Exception:    
                block = str(response.json()['Block']['FIPS'])
                blockdf=pd.DataFrame(pd.Series(block),columns=['FIPS'])
                blockdf['esh_id']=self.esh_id
                blockdf['latitude']=self.lat
                blockdf['longitude']=self.lon
                blockdf = blockdf.ix[:, ['esh_id','latitude','longitude','FIPS']]
                blockdf.columns=[['esh_id','latitude','longitude','BlockCode']]
        return blockdf
    
# Function to loop through the data    
def create_BlockCode_col(data):
    blocks = pd.DataFrame()
    for i in range(0, data.shape[0]):
        blockdf = getCensusBlock(data['esh_id'][i],str(data['latitude'][i]),str(data['longitude'][i])).censusAPIRequest()
        blocks=pd.concat([blocks,blockdf],axis=0,ignore_index=True)
    print("Block Codes generated successfully")
    return blocks

# Execute and export to csv
esh_ids_with_blockcodes=create_BlockCode_col(esh_ids)

if not os.path.exists(os.path.dirname('../data/')):
    try:
        os.makedirs(os.path.dirname('../data/'))
    except OSError as exc: # Guard against race condition
        if exc.errno != errno.EEXIST:
            raise
            
esh_ids_with_blockcodes_final=esh_ids_with_blockcodes.drop_duplicates()

esh_ids_with_blockcodes_final.to_csv('../data/esh_ids_with_blockcodes.csv',index=False)