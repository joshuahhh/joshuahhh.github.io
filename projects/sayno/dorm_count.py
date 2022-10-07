import urllib
import string

dorms = ['Baker', 'Bexley', 'Burton-Conner', 'East Campus',
         'MacGregor', 'McCormick', 'New House', 'Phoenix Group (Maseeh Hall)',
         'Random', 'Next', 'Senior Haus', 'Simmons', 'Alpha Delta Phi',
         'Alpha Epsilon Pi', 'Beta Theta Pi', 'Chi Phi', 'Delta Kappa Epsilon',
         'Delta Psi (No.6)', 'Delta Tau Delta', 'Delta Upsilon', 'Kappa Sigma',
         'Lambda Chi Alpha', 'Nu Delta', 'Phi Beta Epsilon', 'Phi Delta Theta',
         'Phi Kappa Sigma', 'Phi Kappa Theta', 'Phi Sigma Kappa', 'Pi Lambda Phi',
         'Sigma Chi', 'Sigma Nu', 'Sigma Phi Epsilon', 'Tau Epsilon Phi',
         'Theta Chi', 'Theta Delta Chi', 'Theta Xi', 'Zeta Beta Tau', 'Zeta Psi',
         'Alpha Chi Omega', 'Alpha Epsilon Phi', 'Alpha Phi', 'Kappa Alpha Theta',
         'Sigma Kappa', 'Epsilon Theta', 'Fenway House', 'Pika',
         'Student House', 'WILG', 'Off Campus', 'Other']

def get_counts():
    page = urllib.urlopen("http://scripts-cert.mit.edu/~keone/dining/signatures.php").read()
    counts = {}
    for dorm in dorms:
        counts[dorm] = string.count(page, ", " + dorm + "</strong>")
    return counts
