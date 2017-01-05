#! /usr/bin/env python 
# -*- coding: cp936  -*-

# convert excel xls file to lua script with table data
# date/time values formatted as string, int values formatted as int 
# depend on xlrd module
# fanlix 2008.1.25
# Modify:
# 2008.3.18  merged-cell handles: copy data from top-left cell to other cells


import xlrd
import os
import os.path
import string
import math
import hashlib

FLOAT_FORMAT = "%.4f"

def gen_table(filename, luaT):
	if not os.path.isfile(filename):
		raise NameError, "%s is	not	a valid	filename" %	filename
		
	Err = ""
	try:
		book = xlrd.open_workbook(filename,formatting_info=True)	
	except Err:
		print "\u65E0\u6CD5\u89E3\u6790xls", filename
		return

	if not luaT.has_key("__SheetOrder"):
		luaT["__SheetOrder"] = {}
	
	if not luaT["__SheetOrder"].has_key(0):
		luaT["__SheetOrder"][0] = ["string"]
	
	sidx = 0
	for sheet in book.sheets():
		sdict = {}	
		ridx = 0
		#print "-----", sheet.ncols, sheet.nrows
		types = {}
		
		#check valid rows
		rows_count = sheet.nrows
		for r in xrange(sheet.nrows):
			tmp_count = 0
			for c in xrange(sheet.ncols):
				value = sheet.cell_value(r, c)
				vtype = sheet.cell_type(r, c)
				v = format_value(value, vtype, book)
				if v == None:
					tmp_count += 1
			#print "check cols", tmp_count, sheet.ncols
			if tmp_count == sheet.ncols:
				rows_count = r
				break
				
		#check valid cols
		cols_count = sheet.ncols
		for c in xrange(sheet.ncols):
			tmp_count = 0
			for r in xrange(sheet.nrows):
				value = sheet.cell_value(r, c)
				vtype = sheet.cell_type(r, c)
				v = format_value(value, vtype, book)
				if v == None:
					tmp_count += 1
			if tmp_count == sheet.nrows:
				cols_count = c
				break
		
		#print "rows_count", rows_count, "cols_count", cols_count
		for c in xrange(cols_count):
			rdict = range(rows_count)
			for r in xrange(rows_count):
				value = sheet.cell_value(r, c)
				vtype = sheet.cell_type(r, c)
				v = format_value(value, vtype, book)
				#print "--", vtype, "==",  value
				if v is not None and value != "": 
					#print sheet.name, r, c, v
					rdict[r] = v
				else:
					rdict[r] = "nil"
			sdict[c] = rdict

		# handle merged-cell
#		for crange in sheet.merged_cells:
#			rlo, rhi, clo, chi = crange
#			try:
#				v = sdict[rlo][clo]
#			except KeyError:
#				# empty cell
#				continue
#			if v is None or v == "": continue
#			for ridx in xrange(rlo, rhi):
#				if ridx not in sdict:
#					sdict[ridx] = {}
#				for cidx in xrange(clo, chi):
#					sdict[ridx][cidx] = v
		
		#print "sheet", sheet.name
		luaT[sheet.name] = sdict
		luaT["__SheetOrder"][0].append(sheet.name)
	#print "--------- luaT:", luaT
	return luaT

def format_value(value, vtype, book):
	''' format excel cell value, int?date?
	'''
	if vtype == 1:
		#string
		value = value.replace("\r", " ")
		value = value.replace("\n", " ")
		value = value.replace("\\", "/")
		return value
	elif vtype == 2: 
		#number
		if value == int(value):
			return int(value)
		elif type(value) == float :
			return value
	elif vtype == 3:
		#date
		datetuple =	xlrd.xldate_as_tuple(value,	book.datemode)
		# time only	no date	component
		if datetuple[0]	== 0 and datetuple[1] == 0 and datetuple[2] == 0: 
			value =	"%02d:%02d:%02d" % datetuple[3:]
		# date only, no	time
		elif datetuple[3] == 0 and datetuple[4]	== 0 and datetuple[5] == 0:
			value =	"%04d/%02d/%02d" % datetuple[:3]
		else: #	full date
			value =	"%04d/%02d/%02d	%02d:%02d:%02d"	% datetuple

def format_output(v):
	#rel = ("%s"%(v)).encode("gbk")
	if type(v) == type(u"t") or type(v) == type("t"):
#		v = v.replace("\"", "")
		if v == "nil":
			return v
		try:
			return add_quoted(v).encode("gbk")
		except Exception:
			try:
				#print "---",  type(v), len(v)
				return add_quoted(v).encode("ascii")
			except Exception:
				print "----format value error",  type(v), len(v)
				return "\"unknown_type\""
	else:
		return str(v)
		

def write_table(luaT, header, outfile = '-', withfunc = True):
	''' lua table key index starts from 1
	'''
	if outfile and outfile != '-': 
		filedir = outfile[0:outfile.rfind("/")]
		if not os.path.isdir(filedir):
			try:
				os.makedirs(filedir)
			except Exception:
				print "目录创建出错" + filedir
		print(outfile, filedir)
		outfp = open(outfile, 'w')
		#outfp.write(SCRIPT_HEAD)
	else: 
		import StringIO 
		outfp = StringIO.StringIO()
	
	outfp.write(header+"\n")
	outfp.write("return {\n")
	for name, sheet in luaT.items():
		#print "----", len(name), name, name.encode("gb2312"), name.encode("gbk")
		#name = format_output(name).replace("\"", "")
#		name = name.replace("\"", "")
		outfp.write("[%s] = {\n" % format_output(name))
		for field, contents in sheet.items():
			keys = string.ascii_uppercase
			q = len(keys)
			hi = int(field / q)
			lo = int(field % q)
			kname = keys[lo]
			if hi > 0:
				kname = keys[hi-1] + kname
			outfp.write("\t\t[%s] = {" % (format_output(kname)))
			for v in contents:
				outfp.write("%s, "%format_output(v))
			outfp.write("},\n")
		outfp.write("\t},\n")
	outfp.write("}")
	outfp.close()

# clone from lua5.1.3's  string.format("%q", src_str) C implementation
# note: Python's \xxx meanning diff from Lua's! 
def add_quoted(src_str):
	dst_str = "\""
	for c in src_str:
		if c in ('"', '\\', '\n'):
			dst_str += '\\' + c
		elif c == '\r':
			dst_str += '\\r'
		elif c == '\0':
			dst_str += '\\000'
		else:
			dst_str += c
	
	dst_str += "\""
	return dst_str

# 读取文件，获取文件的 md5 码
def get_file_md5(file):
	try:
		inputfp = open(file, "rb")
	except IOError, Err:
		raise "打开输入文件失败：", Err
	xls_buff = inputfp.read()
	inputfp.close()
	
	# 计算xls文件的md5
	m = hashlib.md5()
	m.update(xls_buff)
	md5_str = m.hexdigest()
	return md5_str

XLS_MD5_TAG = "-- xls md5:"

def can_skip(outputfile, filemd5_list):
	md5_str = ""
	for md5 in filemd5_list:
		md5_str = md5_str + md5 + ","

	try:
		outputfp = open(outputfile, "r")
	except IOError, Err:
		print "需要重新导出"
		return False, md5_str
		
	frist_line = None
	for line in outputfp:
		frist_line = line
		break
	outputfp.close()
	
	if frist_line == None:
		print "[" + outputfile + "]为空文件，需要重新导出"
		return False, md5_str
	
	if not frist_line.startswith(XLS_MD5_TAG):
		print "[" + outputfile + "]第一行不存在md5码，需要重新导出"
		return False, md5_str

	# 获取 *.xls.lua中标志的xls md5
	md5_str_in_lua = frist_line.replace(XLS_MD5_TAG, "").strip()

	if len(md5_str_in_lua) != len(md5_str):
		print "md5 不一致，需要重新导出"
		return False, md5_str

	for md5 in filemd5_list:
		if md5_str_in_lua.find(md5) < 0 :
			print "md5 不一致，需要重新导出"
			return False, md5_str
	
	print "md5一致，跳过[" + outputfile + "]文件的导出"
	return True, md5_str
	

if __name__=="__main__":
	import sys
	
	# to be delete ...
	#if len(sys.argv) < 2:
	#	sys.exit('''\u53C2\u6570\u4E0D\u5168\uFF0C\u8BF7\u6307\u5B9Axls\u6587\u6863\u6240\u5728\u76EE\u5F55\u53CA\u8F93\u51FA\u76EE\u5F55''')

	if (len(sys.argv) < 1):
		sys.exit("缺少参数1：python xls2lua.py ../S数值表/导表文件.xls")

	in_dir = sys.argv[1]
	in_dir = in_dir.replace("\\", "/")

	in_dir_len = len(in_dir)
	if (in_dir[in_dir_len - 4:in_dir_len] != ".xls"):
		sys.exit("文件格式错误，导表的文件必须是 xls 结尾的文件 : " + in_dir)

	# to be delete ...
	#if not is_can_skip:
	#	header = XLS_MD5_TAG + xls_md5_str
	#	write_table(gen_table(in_dir, {}), header, out_dir, withfunc = True)

	# 获取导表文件名字
	filepath = "./"
	s_idx = in_dir.rfind("/")
	if (s_idx <= 0):
		s_idx = 0
	else:
		s_idx = s_idx + 1
		filepath = in_dir[0:s_idx]
	e_idx = in_dir.find(".", s_idx)
	key = in_dir[s_idx:e_idx]

	# 计算输出文件名、路径 - ../lua/原路径/key.xls.lua
	out_dir = "../lua/"
	replace_list = {"S数值表/":"数值表/", "M美术资源/":"资源表/"}
	for BasePath, TarPath in replace_list.items():
		find_idx = filepath.find(BasePath)
		if find_idx >= 0:
			out_dir = out_dir + TarPath + filepath[find_idx + len(BasePath):len(filepath)] + key + ".xls.lua"
			print "OutKey:" + out_dir	# proxy.lua 用于读取输出输出的文件名
			break
	
	# 获取所有需要导表的 md5
	filename_list = []
	filemd5_list = []
	for filename in os.listdir(filepath):
		filelen = len(filename)
		if (filename[filelen - 4:filelen] == ".xls"):	# 搜索 *.xls 文件
			if (filename.find(key+".") == 0):			# 搜索 名字类似 文件
				fullpath = filepath+filename
				filename_list.append(fullpath)
				filemd5_list.append(get_file_md5(fullpath))


	# 并遍历查找相同类型名字的文件
	out_table = {}
	for filename in filename_list:
		gen_table(filename, out_table)
	
	# 输出文件
	is_can_skip, xls_md5_str = can_skip(out_dir, filemd5_list)
	if not is_can_skip:
		header = XLS_MD5_TAG + xls_md5_str
		write_table(out_table, header, out_dir, withfunc = True)
	
	# to be delete ...
#	for root, dirs, files in os.walk(in_dir):
#		for f in files:
#			if (f.find(".svn") >= 0) or (f.find(".xls") <= 0 and f.find(".xls")+4 != len(f)):
#				continue     
#			fullpath = root + "/" + f 
#			if os.path.exists(fullpath) is False:
#				continue         
#			outfile = fullpath
#			outfile = outfile.replace(in_dir, out_dir)
#			outfile = outfile.replace(".xls", ".xls.lua")
#			is_can_skip, xls_md5_str = can_skip(fullpath, outfile)
#			if is_can_skip:
#				continue                   
#			print fullpath, "-->", outfile
#			header = XLS_MD5_TAG + xls_md5_str
#			write_table(gen_table(fullpath, {}), header, outfile, withfunc = True)

