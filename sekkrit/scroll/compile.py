#!/usr/bin/env python

import argparse
import os
import time
import markdown
import pyjade
import subprocess

JADES = ['index', 'anim', 'scheduler', 'twogames', 'gate', 'constructncount']

def compile_jade(src, global_context={}):
    _parser = pyjade.parser.Parser(src)
    block = _parser.parse()
    _compiler = pyjade.ext.html.HTMLCompiler(block)
    _compiler.global_context = global_context
    return _compiler.compile().strip()

def update_jade(file_prefix):
    input = open(file_prefix + ".jade").read()
    output = compile_jade(input)
    open(file_prefix + ".html", "w").write(output)

def compile():
    print "compiling"

    map(update_jade, JADES)

def loop():
    deps = [j + '.jade' for j in JADES]
    mtimes_last = None
    while True:
        time.sleep(0.1)
        mtimes_cur = map(os.path.getmtime, deps)
        if mtimes_cur != mtimes_last:
            compile()
        mtimes_last = mtimes_cur

if __name__ == "__main__":
    # subprocess.Popen("coffee -bcw *.coffee", shell=True, stdout=subprocess.PIPE)

    loop()
    """
    parser = argparse.ArgumentParser(
        description="")
    parser.add_argument("source",
                        help="Markdown file to process")
    parser.add_argument("--monitor", action="store_true", default=False,
                        help="Turn on monitor mode")
    parser.add_argument("--template",
                        help="Template file to use")
    """
