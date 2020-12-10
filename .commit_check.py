#!python3
import os
import sys
import subprocess
import re
from git import Repo

def do_commit_check(fn, verbose=False): 
    cmd = "clang-format-6.0 -style=file -output-replacements-xml {}".format(fn)
    if verbose:
        print(cmd)
        print("[COMMIT_CHECK] processing file %s: "%(fn), end=' ')
    res, _err = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE).communicate()
    if len(re.findall(b"\\breplacement\\b", res)) > 0:
        if verbose:
            print("Failed", end=' ')
            print(" Fixing", end=' ')
        cmd = "clang-format -i -style=file %s"%fn
        res, _err = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE).communicate() 
        if verbose:
            print("Fixed")

    elif verbose:
        print("passed")

    return

git_tokens=['modified', 'new file']


def analyze_all(file_list, verbose=False):
    allFiles=  len(file_list)
    if allFiles ==0:
        return
    maxb = 50
    maxStr = len(max(file_list,key=len))

    for index,filen in enumerate(fnlist):
        sys.stdout.write('\r')
        prog = (index*100)//allFiles
        sys.stdout.write("Format : [%-*s] %d%% %-*s" % (maxb,'#'*((index*maxb)//allFiles), prog , maxStr, filen))
        sys.stdout.flush()
        do_commit_check(filen, verbose)
    
    # Done 
    sys.stdout.write('\r')
    print("Format : [%-*s] %d%% %-*s" % (maxb, '#'*maxb, 100,maxStr, ""))

if __name__=="__main__":
    repo=Repo()
    git = repo.git
    k = git.status()
    k=k.splitlines()
    fnlist = []
    for line in k:
        toks= line.split(':')
        if len(toks) < 2:
            continue

        if toks[0].strip() in git_tokens:
            filename = toks[1].strip().encode('ascii', 'ignore')
            if any ( [ filename.endswith(bytes(x, 'utf-8')) for x in ['.c','.h', '.cpp', '.hpp' ] ] ):
                fnlist.append(filename.decode())
        continue
    print("[COMMIT_CHECK] %d Files modifed"%len(fnlist))
    analyze_all(fnlist, True if len(sys.argv) >1 else False )
