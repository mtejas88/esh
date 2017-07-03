##NOT USED
##regression with test/train -- c2 only
lowcost_applications_c2  = lowcost_applications.loc[lowcost_applications['category_2'] == True]

#remove outliers
mean_enroll = np.mean(lowcost_applications_c2['fulltime_enrollment'])
std_enroll = np.std(lowcost_applications_c2['fulltime_enrollment'])
mean_recip = np.mean(lowcost_applications_c2['num_recipients'])
std_recip = np.std(lowcost_applications_c2['num_recipients'])
mean_req = np.mean(lowcost_applications_c2['total_funding_year_commitment_amount_request'])
std_req = np.std(lowcost_applications_c2['total_funding_year_commitment_amount_request'])
mean_spin = np.mean(lowcost_applications_c2['num_spins'])
std_spin = np.std(lowcost_applications_c2['num_spins'])

lowcost_applications_c2 = lowcost_applications_c2.loc[abs(lowcost_applications_c2['fulltime_enrollment'] - mean_enroll) < 3 * std_enroll]
lowcost_applications_c2 = lowcost_applications_c2.loc[abs(lowcost_applications_c2['num_recipients'] - mean_recip) < 3 * std_recip]
#lowcost_applications_c2 = lowcost_applications_c2.loc[abs(lowcost_applications_c2['total_funding_year_commitment_amount_request'] - mean_req) < 3 * std_req]
#lowcost_applications_c2 = lowcost_applications_c2.loc[abs(lowcost_applications_c2['num_spins'] - mean_spin) < 3 * std_spin]

#define model inputs
train, test = train_test_split(lowcost_applications_c2, train_size=0.75, random_state=1)

feature_cols = ['consultant_indicator', 'applicant_type_School',  'fulltime_enrollment', 'num_recipients', 'maintenance_indicator', 'managedbb_indicator', 'connections_indicator', '0bids_indicator', '1bids_indicator', 'prevyear_indicator', 'num_spins']

insig_cols = ['locale_Rural', 'category_one_discount_rate', 'special_construction_indicator', 'applicant_type_School District', 'applicant_type_Consortium', 'applicant_type_Library', 'num_service_types', 'total_funding_year_commitment_amount_request', 'frns', 'mastercontract_indicator']

X1 = train[feature_cols]
y1 = train.denied_indicator

#run regression model on train set
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X1,y1)
rows = X_res.shape[0]

X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

X_res = sm.add_constant(X_res)

est1 = sm.Logit(y_res, X_res.astype(float)).fit()
print(est1.summary())

#predict on test set
x_test = test[feature_cols]
x_test = sm.add_constant(x_test)

y_test = test.denied_indicator

yhat_test = est1.predict(x_test)
#plt.hist(yhat_test,50)
#plt.show()

yhat_test = [ 0 if y < 0.35 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))

##regression with test/train
train, test = train_test_split(lowcost_applications, train_size=0.75, random_state=1)

X1 = train[feature_cols]
y1 = train.denied_indicator

# regression model
rus = RandomUnderSampler(random_state=1)
X_res, y_res = rus.fit_sample(X1,y1)
rows = X_res.shape[0]

X_res =  pd.DataFrame(data=X_res, index=range(rows), columns=feature_cols)
y_res =  pd.DataFrame(data=y_res, index=range(rows), columns=['denied_indicator'])

X_res = sm.add_constant(X_res)

est1 = sm.Logit(y_res, X_res.astype(float)).fit()
print(est1.summary())

# predicting
x_test = test[feature_cols]
x_test = sm.add_constant(x_test)

y_test = test.denied_indicator

yhat_test = est1.predict(x_test)
plt.hist(yhat_test,50)
plt.show()

yhat_test = [ 0 if y < 0.35 else 1 for y in yhat_test ]

print(confusion_matrix(y_test, yhat_test))
print(classification_report(y_test, yhat_test,digits=3))

##regression for low cost -- first regression for evan
# modeling prep
feature_cols = ['no_consultant_indicator', 'special_construction_indicator', 'applicant_type_School', 'locale_Urban', 'category_2', 'fulltime_enrollment','num_recipients', 'num_service_types', 'category_one_discount_rate']

insig_cols = ['applicant_type_School District','applicant_type_Consortium','applicant_type_Library']

X = lowcost_applications[feature_cols]
y = lowcost_applications.denied_indicator


# regression model
X = sm.add_constant(X)
est = sm.Logit(y, X.astype(float)).fit()
print(est.summary())

##how many apps with worst case were denied funding
wor = lowcost_applications.groupby(['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2'])
print(wor.agg({'application_number': lambda x: x.count()}))

## histograms of all variables
hist_cols = ['no_consultant_indicator', 'special_construction_indicator', 'services_2p_indicator', 'applicant_type_School', 'locale_Urban', 'category_2', 'denied_indicator']
lowcost_applications[hist_cols].hist()
pylab.show()
