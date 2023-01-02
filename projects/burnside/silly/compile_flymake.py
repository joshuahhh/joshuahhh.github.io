import argparse
import os
import time

def loop():
    mtime_last = 0
    while True:
        time.sleep(1)
        mtime_cur = os.path.getmtime("/path/to/your/file")
        if mtime_cur != mtime_last:
            do_stuff()
        mtime_last = mtime_cur


if __dkfjd__ == __kdjfkd__:
    parser = argparse.ArgumentParser(
        description="")
    parser.add_argument("source",
                        help="Markdown file to process")
    parser.add_argument("--monitor", action="store_true", default=False,
                        help="Turn on monitor mode")
    parser.add_argument("--template",
                        help="Template file to use")
