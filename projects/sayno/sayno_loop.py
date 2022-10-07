import datetime
import re
import urllib
import matplotlib
import matplotlib.figure
import matplotlib.backends.backend_agg
import time

import dorm_count
import pie

def make_graphs():
    url = "http://scripts-cert.mit.edu/~keone/dining/signatures.php"
    page = urllib.urlopen(url).read()
    text_dates = re.findall("<em>[^<>]*</em>", page)
    sig_dates = [datetime.datetime.strptime(s[7:-5], "%B %d, %Y, %I:%M %p")
                 for s in text_dates]
    sig_nums = map(matplotlib.dates.date2num, sig_dates)

    # Line graph
    
    fig = matplotlib.figure.Figure(figsize=(10,7.5))
    ax = fig.add_subplot(111)
    ax.plot(sig_nums[1:],range(1,len(sig_nums)), '-')
    ax.xaxis.set_major_locator(matplotlib.dates.HourLocator(byhour = range(0,24,6)))
    ax.xaxis.set_major_formatter(matplotlib.dates.DateFormatter('%m/%d %I:%M %p'))
    fig.suptitle("Signatures on \"The Campus Dining Petition\" (sayno.mit.edu)")
    fig.autofmt_xdate()

    canvas = matplotlib.backends.backend_agg.FigureCanvasAgg(fig)
    canvas.print_figure("sayno.png", dpi=80)

    # Pie chart (mpl)

    fig = matplotlib.figure.Figure(figsize=(10,7.5))
    ax = fig.add_subplot(111, aspect='equal')
    dorm_counts = dorm_count.get_counts()
    for k, v in dorm_counts.items():
        if v < 10:
            del dorm_counts[k]
    ax.pie(dorm_counts.values(), labels=dorm_counts.keys(), labeldistance=1.25)

    canvas = matplotlib.backends.backend_agg.FigureCanvasAgg(fig)
    canvas.print_figure("sayno_dorms.png", dpi=80)

    # Pie chart (google)

    pie.make_hackish_google_pie_chart();

num_renders = 0

while True:
    print "rendering..."
    try:
        make_graphs()
        num_renders = num_renders + 1
        print num_renders, " graphs rendered"
        time.sleep(60)
    except KeyboardInterrupt:
        exit()
    except:
        print "hey something bad happened checkitout"
