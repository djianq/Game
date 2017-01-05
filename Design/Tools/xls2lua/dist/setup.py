##! /usr/bin/env python # -*- coding: cp936  -*-

# convert excel xls file to lua script with table data
# date/time values formatted as string, int values formatted as int 
# depend on xlrd module
# fanlix 2008.1.25
# Modify:
# 2008.3.18  merged-cell handles: copy data from top-left cell to other cells

# mysetup.py
from distutils.core import setup
import py2exe

setup(console=["xls2lua.py","csv2xls.py"])
