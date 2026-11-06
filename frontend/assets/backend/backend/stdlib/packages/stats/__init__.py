import numpy as np
import scipy.stats as stats

def normal_pdf(x=None, mu=0, sigma=1):
    return stats.norm.pdf(x, mu, sigma)

def normal_cdf(x=None, mu=0, sigma=1):
    return stats.norm.cdf(x, mu, sigma)

def poisson_pdf(k=None, mu=None):
    return stats.poisson.pmf(k, mu)

def t_test(a=None, b=None):
    """
    Perform a T-test for the means of two independent samples of scores.
    """
    t_stat, p_val = stats.ttest_ind(np.asarray(a).flatten(), np.asarray(b).flatten())
    return t_stat, p_val

def anova(*args):
    """
    Perform one-way ANOVA.
    """
    flat_args = [np.asarray(a).flatten() for a in args]
    f_stat, p_val = stats.f_oneway(*flat_args)
    return f_stat, p_val

def linear_regression(x=None, y=None):
    """
    Calculate a linear least-squares regression for two sets of measurements.
    """
    res = stats.linregress(np.asarray(x).flatten(), np.asarray(y).flatten())
    return {
        'slope': res.slope,
        'intercept': res.intercept,
        'rvalue': res.rvalue,
        'pvalue': res.pvalue,
        'stderr': res.stderr
    }

def correlation(a=None, b=None):
    return np.corrcoef(a, b)[0, 1]

def skewness(data=None):
    return stats.skew(data)

def kurtosis(data=None):
    return stats.kurtosis(data)

def summary(data=None):
    """
    Returns a comprehensive statistical summary.
    """
    return {
        'mean': np.mean(data),
        'median': np.median(data),
        'std': np.std(data),
        'var': np.var(data),
        'min': np.min(data),
        'max': np.max(data),
        'skew': float(stats.skew(data)),
        'kurtosis': float(stats.kurtosis(data))
    }
