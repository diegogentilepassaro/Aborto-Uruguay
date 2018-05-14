#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
from distutils.dir_util import copy_tree
copy_tree("../../../library/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
copy_tree("../../../library/python/gslab_fill", "./gslab_fill") # Copy from gslab tools stored locally

from gslab_make.get_externals import *
from gslab_make.make_log import *
from gslab_make.make_links import *
from gslab_make.make_link_logs import *
from gslab_make.run_program import *
from gslab_make.dir_mod import *

stata_exe = os.environ.get('STATAEXE')
if stata_exe:
    import copy
    default_run_stata = copy.copy(run_stata)
    def run_stata(**kwargs):
        kwargs['executable'] = stata_exe
        default_run_stata(**kwargs)

#****************************************************
# MAKE.PY STARTS
#****************************************************
# SET DEFAULT OPTIONS
set_option(link_logs_dir = '../output/')
set_option(output_dir = '../output/', temp_dir = '../temp/')
#clear_dirs('../temp/')
#delete_files('../output/*')

start_make_logging()

#run_stata(program = 'diff_in_diff.do')

from gslab_fill.tablefill import tablefill
from gslab_fill.textfill import textfill

tablefill(
	input = ('../output/tables.txt'),
	template = '../source/table_rivera.lyx',
	output = '../output/table_rivera_filled.lyx'
	)

tablefill(
	input = ('../output/tables.txt'),
	template = '../source/table_salto.lyx',
	output = '../output/table_salto_filled.lyx'
	)

tablefill(
	input = ('../output/tables.txt'),
	template = '../source/table_florida.lyx',
	output = '../output/table_florida_filled.lyx'
	)

run_lyx(program = '../output/table_rivera_filled.lyx')
run_lyx(program = '../output/table_salto_filled.lyx')
run_lyx(program = '../output/table_florida_filled.lyx')

os.rename('../output/table_rivera_filled.pdf', '../output/table_rivera.pdf')
os.rename('../output/table_salto_filled.pdf', '../output/table_salto.pdf')
os.rename('../output/table_florida_filled.pdf', '../output/table_florida.pdf')

end_make_logging()

shutil.rmtree('gslab_make')
input('\n Press <Enter> to exit.')

