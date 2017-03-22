import pandas as pd
import numpy as np
import glob
import csv

frn_data = pd.DataFrame()
recip_data = pd.DataFrame()
#outputFile =open#"/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/combined_test.csv","w")

files = glob.glob("*Current_*.xlsx")


for f in files:
	print f
	df = pd.read_excel(f,sheetname='FRN Line Items',header=0,converters={'Line Item': str})
	df2 = pd.read_excel(f,sheetname='Recipients Of Service',header=0,converters={'Line Item': str})
	frn_data = frn_data.append(df,ignore_index=True)
	recip_data = recip_data.append(df2,ignore_index=True)
	
frn_data.to_csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/all_frn.csv", encoding='utf-8')
recip_data.to_csv("/Users/jeremyholtzman/Documents/Analysis/Current 2016 471s/all_recip.csv", encoding='utf-8')
