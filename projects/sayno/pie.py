import dorm_count
import operator
import os
import string

def make_hackish_google_pie_chart():
    l = sorted([(k,v) for k, v in dorm_count.get_counts().iteritems() if v > 0],
               key = operator.itemgetter(0)) #, reverse = True)

    # labels
    lk = map(lambda (k,v) : string.replace(k, " (Maseeh Hall)", "") + " (" + str(v) + ")", l)
    # data
    lv = map(str, map(operator.itemgetter(1), l))

    os.system("rm sayno_dorms_alt.png")
    os.system("curl " + string.replace( \
        '"http://chart.apis.google.com/chart?chs=680x440&cht=p&chp=0' + \
          "&chma=0,0,0,30&chds=0,1000" + \
          "&chd=t:" + ",".join(lv) + \
          "&chl=" + "|".join(lk) + '"', \
        ' ', '+') + " >> sayno_dorms_alt.png")
