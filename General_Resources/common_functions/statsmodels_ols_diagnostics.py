###Model diagnostics - takes in a statsmodel OLS model object
import scipy 
import numpy
from numpy import linalg
from scipy import stats
import statsmodels.api 
import matplotlib.pyplot 
import pandas
from statsmodels.graphics.regressionplots import * 
from statsmodels.stats.diagnostic import linear_harvey_collier

def ols_model_diagnostics(model):

#residuals should look normal - this plot should be more of less a straight line
    print('Residuals QQ-Plot')
    fig = statsmodels.api.qqplot(model.resid, scipy.stats.t, fit=True, line='r')
    matplotlib.pyplot.show()

    #residuals vs. fitted values - this should look random/no pattern
    stdres = pandas.DataFrame(model.resid_pearson)
    fig = matplotlib.pyplot.plot(stdres, 'o', ls='none')
    l = matplotlib.pyplot.axhline(y=0, color='r')
    matplotlib.pyplot.ylabel('Standardized Residual')
    matplotlib.pyplot.xlabel('Observation')
    print fig

    #leverage statistics vs. normalized residuals squared 
    plot_leverage_resid2(model)
#influence plot: studentized resids vs. leverage. The combination of large residuals and a high leverage (influence on estimation of the model coefficients) indicates an influence point. In both of these plots, mostly checking to see that most points have low leverage
    influence_plot(model)

    #test for nonlinearity: looking for the p-value here to be > 0.05 to meet the linearity assumption
    try:
        print linear_harvey_collier(model)
    except linalg.LinAlgError:
        print "Error: Singular covariance matrix, Harvey Collier nonlinearity test not executed"
