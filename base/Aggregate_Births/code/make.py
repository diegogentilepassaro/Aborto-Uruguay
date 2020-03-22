#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from distutils.dir_util import copy_tree
copy_tree("../../../library/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *
from gslab_make.dir_mod import *

envir_vars = os.getenv('PATH')
if envir_vars is None:
    envir_vars = os.getenv('Path')

if "StataSE" in envir_vars:
    stata = "stataSE"
elif "StataMP-64" in envir_vars:
    stata = "StataMP-64"
elif "Stata15" in envir_vars:
    stata = "StataMP-64"

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/')
set_option(output_dir = '../output/', temp_dir = '../temp/')
delete_files('../output/*')

start_make_logging()

run_stata(program = 'agg_births.do', executable = stata)

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')
