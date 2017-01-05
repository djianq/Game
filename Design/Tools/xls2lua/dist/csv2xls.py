#! /usr/bin/env python 
# -*- coding: utf8  -*-

# convert excel xls file to lua script with table data
# date/time values formatted as string, int values formatted as int 
# depend on xlrd module
# fanlix 2008.1.25
# Modify:
# 2008.3.18  merged-cell handles: copy data from top-left cell to other cells


import xlwt
import csv
import os
import os.path
import string
import math
import hashlib
import chardet

FLOAT_FORMAT = "%.4f"

def set_style(name,height,bold=False):
	style = xlwt.XFStyle() # 初始化样式
	
	font = xlwt.Font() # 为样式创建字体
	font.name = name # 'Times New Roman'
	font.bold = bold
	font.color_index = 4
	font.height = height
	
	# borders= xlwt.Borders()
	# borders.left= 6
	# borders.right= 6
	# borders.top= 6
	# borders.bottom= 6
	
	style.font = font
	# style.borders = borders
	
	return style


def csv_to_xls(csvfile, xlsfile, sheetname):
	wb = xlwt.Workbook()
	ws = wb.add_sheet(sheetname)
	try:
		f = open(csvfile, 'rb')
	except IOError, Err:
		raise "打开文件错误", Err

	reader = csv.reader(f,'excel-tab')
	for r, row in enumerate(reader):
		for c, val in enumerate(row):
#			codeinfo = chardet.detect(val)
			encode = "utf-8"
			if c == 1:
				encode = "utf-8"
#			if codeinfo['encoding']:
#				if codeinfo['encoding'] == 'utf-8':
#					encode = codeinfo['encoding']
			try:
				deval = val.decode(encode)
			except Exception:
				deval = val.decode('utf-8')
			ws.write(r, c, deval)
	f.close()
	wb.save(xlsfile)

if __name__=="__main__":
	import sys
	
	if (len(sys.argv) <= 3):
		sys.exit("缺少参数：python csv2xls.py csv文件 xls文件 sheetname")

	if os.path.isfile(sys.argv[1]) :
		csv_to_xls(sys.argv[1], sys.argv[2], sys.argv[3])

#	elif os.path.isdir(sys.argv[1]) :
#		for root, dirs, files in os.walk(sys.argv[1]):
#			for f in files:
#				if (f.find(".svn") >= 0) or (f.find(".xls") <= 0 and f.find(".xls")+4 != len(f)):
#					continue     
#				fullpath = root + "/" + f 
#				make_luafile(fullpath)


