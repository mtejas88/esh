#Script to connect to the db in Python and store the result of a query in a pandas dataframe. 
#Not intended to be a standalone function, but just a reminder of the syntax. Feel free to modify as needed!

import os
#need to install psycopg2
import psycopg2

#It's best if you store HOST, USER, PASSWORD and DB for out postgres database as environment variables on your computer - i.e.,:
#in your .bash_profile, add export statements for each variable such as ' export USER="ud1bnbevrqe2q" '
HOST = os.environ.get("HOST")
USER = os.environ.get("USER")
PASSWORD = os.environ.get("PASSWORD")
DB = os.environ.get("DB")

#iniitalize a connection and a cursor
conn = psycopg2.connect( host=HOST, user=USER, password=PASSWORD, dbname=DB )
cur = conn.cursor()

#execute a query from a string directly:
cur.execute("select esh_id, latitude, longitude from public.fy2016_districts_deluxe_matr")

#fetch the query result and put it in a dataframe
names = [x[0] for x in cur.description]
rows = cur.fetchall()
df1 = pd.DataFrame(rows, columns=names)

#and/or, execute a query from a file:
queryfile=open('filepath/query.sql', 'r')
query = queryfile.read()
queryfile.close()
cur.execute(query)

#fetch the query result and put it in a dataframe
names = [x[0] for x in cur.description]
rows = cur.fetchall()
df2 = pd.DataFrame(rows, columns=names)

