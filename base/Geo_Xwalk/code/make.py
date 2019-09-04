#! /usr/bin/env python
#****************************************************
# GET LIBRARY
#****************************************************
import subprocess, shutil, os
# gslab_make_path = os.getenv('local_make_path')
# gslab_fill_path = os.getenv('local_fill_path')
from distutils.dir_util import copy_tree
copy_tree("../../../library/python/gslab_make", "./gslab_make") # Copy from gslab tools stored locally
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
delete_files('../output/*')

start_make_logging()

#os.system('Rscript spss_to_dta.R')
run_stata(program = 'create_loc_Xwalk.do')

end_make_logging()

shutil.rmtree('gslab_make')
shutil.rmtree('gslab_fill')
input('\n Press <Enter> to exit.')

