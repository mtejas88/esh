import os
import re
import numpy as np

##SET DIRECTION AND READ FILE
os.chdir('/Users/jeremyholtzman/Documents/Analysis/ficher/General_Resources/Views/2017')
f = open('fy2017_bw_indicator_matr.sql', 'r').read().lower()


##TURN TEXT INTO ARRAY
words = re.sub("\\)", "", f)
words = re.sub("\\s", " ",  words).split()
last_position = words.index('author:')
words = words[0:last_position]

##FUTURE IMPORVEMENT: Remove comments from files

##FIND KEY WORDS (FROM, JOIN)
from_positions = [i for i, x in enumerate(words) if x == "from"]
join_positions = [i for i, x in enumerate(words) if x == "join"]

##FIND ALL TABLES
tables = []
for position in from_positions:
	tables.append(words[position + 1])

for position in join_positions:
	tables.append(words[position + 1])

to_remove = ['(', 'temp', 'li_lookup', 'so', 'temp2', '"exclude_from_analysis"']
tables = np.unique(tables).tolist()

for word in to_remove:
	try:
		tables.remove(word)
	except ValueError:
		pass

print(tables)
