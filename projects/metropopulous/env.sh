#!/bin/bash

gnome-terminal --tab -e "coffee -c -w -b cities.coffee" --tab -e "python -m SimpleHTTPServer"
gnome-terminal --tab -e "emacs -nw cities.coffee"
