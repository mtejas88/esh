##Diensioning consultant applications
import os
os.chdir('C:/Users/jesch/OneDrive/Documents/GitHub/ficher/Projects/streamlined_app') 

##packages
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


## data prep
applications = pd.read_csv('data/interim/applications.csv')
applications['discount_category'] = np.floor(applications['category_one_discount_rate']/10)*10
denied_applications = applications.loc[applications['denied_frns'] > 0]
denied_applications  = denied_applications.loc[applications['lowcost_indicator'] == True]


##all denied apps
denied = denied_applications.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'})
print(denied_applications.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

##dimension service category
cat = denied_applications.groupby('category_of_service')
print(cat.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = cat.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = [1, 2]
axis_label = ['Cat 1', 'Cat 2']
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_category.png")

##dimension discount rate
dr = denied_applications.groupby('discount_category')

print(dr.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

print(denied_applications['category_one_discount_rate'].agg([np.median]))

#plot diffs
y = dr.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
#plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
#plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_discount.png")

##dimension applicant type
sc = denied_applications.groupby('applicant_type')
print(sc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = sc.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
#plt.get_figlabels
#plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
#plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_applicant.png")

##dimension special construction
c_sc = denied_applications.groupby('special_construction_indicator')
print(c_sc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = c_sc.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xlabel('Special Construction Indicator')
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
plt.annotate(str(round(y.application_number[0],2)*100)+'%', xy=(.9, y.application_number[0]-.01), xytext=(.9, y.application_number[0]-.01), color = "grey")
plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(1.9, y.application_number[1]), xytext=(1.9, y.application_number[1]), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_special_construction.png")

##dimension consultant
c = denied_applications.groupby('consultant_indicator')
print(c_sc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = c.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xlabel('Consultant Indicator')
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
plt.annotate(str(round(y.application_number[0],2)*100)+'%', xy=(.9, y.application_number[0] + .01), xytext=(.9, y.application_number[0]  + .01), color = "grey")
plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(1.9, y.application_number[1] + .01), xytext=(1.9, y.application_number[1]+ .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_consultant.png")

##dimension locale
loc = denied_applications.groupby('urban_rural_status')
print(loc.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = loc.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913","#F09221"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, axis_label)
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
plt.annotate(str(round(y.application_number[0],2)*100)+'%', xy=(.9, y.application_number[0] + .01), xytext=(.9, y.application_number[0]  + .01), color = "grey")
plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(1.9, y.application_number[1] + .01), xytext=(1.9, y.application_number[1]+ .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_locale.png")

##dimension SPINs
sp = denied_applications.groupby('num_spins')
print(sp.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = sp.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
axis_label = y.index
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, axis_label)
plt.xlabel('# of SPINs')
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
#plt.get_figlabels
#plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
#plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_SPINs.png")

##dimension recipients
rec = denied_applications.groupby('num_recipients')
print(rec.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = rec.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, x)
plt.xlabel('# of recipients')
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
#plt.get_figlabels
#plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
#plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_recipients.png")

##dimension service types
st = denied_applications.groupby('num_service_types')
print(st.agg({'application_number': lambda x: x.count(),  'total_funding_year_commitment_amount_request':'sum'}))

#plot diffs
y = st.agg({'application_number': lambda x: x.count()/denied['application_number']})
x = range(1, len(y)+1)
width = 1/1.5

plt.bar(x, y.application_number, width, color=["#FDB913"], align = 'center')
plt.suptitle('Breakdown of \nDenied Low Cost Applications', fontsize = 18)
plt.xticks(x, x)
plt.xlabel('# of service types')
plt.ylabel('% of Denied Low Cost Applications')
plt.ylim(0,1)
#plt.get_figlabels
plt.annotate(str(round(y.application_number[1],2)*100)+'%', xy=(.9, y.application_number[1] + .01), xytext=(.9, y.application_number[1]+ .01), color = "grey")
plt.annotate(str(round(y.application_number[2],2)*100)+'%', xy=(1.9, y.application_number[2] + .01), xytext=(1.9, y.application_number[2] + .01), color = "grey")
plt.annotate(str(round(y.application_number[3],2)*100)+'%', xy=(2.9, y.application_number[3] + .01), xytext=(2.9, y.application_number[3] + .01), color = "grey")
plt.show()
plt.savefig("figures/denied_apps_by_services.png")
