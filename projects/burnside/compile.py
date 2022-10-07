#!/usr/bin/env python

import argparse
import os
import time
import markdown
import pyjade
import subprocess

import josh_markdown

md = markdown.Markdown(extensions=["extra", josh_markdown.makeExtension()])
# no "nl2br"

def compile_jade(src, global_context={}):
    _parser = pyjade.parser.Parser(src)
    block = _parser.parse()
    _compiler = pyjade.ext.html.HTMLCompiler(block)
    _compiler.global_context = global_context
    return _compiler.compile().strip()

def compile():
    print "compiling"

    content = md.convert(
        open("index.markdown").read())

    out = compile_jade(
        open("index.jade").read(),
        {"content": content})

    open("index.html", "w").write(out)


def loop():
    deps = ["index.jade", "index.markdown", "necklaces.js"]
    mtimes_last = None
    while True:
        time.sleep(0.1)
        mtimes_cur = map(os.path.getmtime, deps)
        if mtimes_cur != mtimes_last:
            compile()
        mtimes_last = mtimes_cur

if __name__ == "__main__":
    subprocess.Popen("coffee -bcw *.coffee", shell=True, stdout=subprocess.PIPE)

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
