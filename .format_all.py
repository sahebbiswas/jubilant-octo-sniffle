#!python3
import os
import sys
import subprocess
import re
import imp

try:
    # Attemp to load ignore file, if present
    with open('.formatignore.py', 'rb') as fp:
        ignore = imp.load_module(
            'ignore',
            fp, 
            '.formatignore.py',
            ('.py', 'rb', imp.PY_SOURCE) )
except FileNotFoundError:
    ignore=None

if __name__=="__main__":
    index = 0
    for root, dirname, filenames in os.walk('.'):
        for filename in filenames:
            if filename.endswith(('.c', '.h', '.cpp','.hpp')):
                fn = "%s/%s"%(root, filename)
                
                if ignore is not None and ignore.skip(fn):
                    continue
                if 0 == index%40:
                    print("\n [%.2d] "%index, end=' ')
                
                index+=1
                cmd = "clang-format -i -style=file %s"%fn
                res, err = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE).communicate()
                sys.stdout.write('.')
                sys.stdout.flush()
    print(("\n : Done : %d files formatted"%index))