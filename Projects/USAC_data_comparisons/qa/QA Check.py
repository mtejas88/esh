import pandas as pd
import numpy as np
import glob
import csv


files = glob.glob("*Current_*.xlsx")
sum_rows = 0

for f in files:
	print f
	df = pd.read_excel(f,sheetname='FRN Line Items',header=0,converters={'Line Item': str})
	sum_rows += len(df.index)
	print sum_rows


df2 = pd.read_csv('/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/all_frn.csv')
all_rows = len(df2.index)


if all_rows == sum_rows:
	print('QA Step A passes')
else:
	print('QA failed. The combined file had ', all_rows, 'and the sum of the individual files had ' sum_rows, 'rows')
