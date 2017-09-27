##imports and definitions
#import packages
from pandas import DataFrame

#import environment variables
import os
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())
GITHUB = os.environ.get("GITHUB")

##query data
def getData( conn, filename ) :
    #source of sql files
    os.chdir(GITHUB+'/Projects/streamlined_app/src/sql') 
    #query data
    cur = conn.cursor()
    cur.execute(open(filename, "r").read())
    names = [ x[0] for x in cur.description]
    rows = cur.fetchall()
    return DataFrame( rows, columns=names)
    
    
