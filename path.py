#!/usr/bin/env python3

# This program is meant to be used from the script setpath.
# The typical use scenario is as follows. You go to some directory where you
# want to do some work. This directory contains various executables. To add
# all of them to your PATH, say
#   . setpath
# It is safe to rerun this command later if more directories are added.
# You can also say
#   . setpath -remove
# if you want to delete all subdirectories of the current directory from the
# path.

from os import access, getcwd, getenv, listdir, pathsep, X_OK
from os.path import abspath, isabs, isdir, isfile, join
from sys import argv, stderr, stdout

new_path = []
new_path_set = set(new_path)
executables = dict()
all_dirs = set()

def add_to_path(directory):
  if directory not in new_path_set:
    new_path.append(directory)
    new_path_set.add(directory)

def process(directory):
  assert isabs(directory)
  hasNewExecutable = False
  subdirs = listdir(directory)
  for f in subdirs:
    fa = abspath(join(directory, f))
    if f[0] != '.' and isfile(fa) and access(fa, X_OK):
      if f not in executables:
        hasNewExecutable = True
        executables[f] = []
      executables[f].append(directory)
  if hasNewExecutable:
    add_to_path(directory)
  for d in subdirs:
    da = join(directory, d)
    if d[0] != '.' and isdir(da):
      process(da)

def collect(directory):
  assert isabs(directory)
  all_dirs.add(directory)
  for d in listdir(directory):
    da = join(directory, d)
    if isdir(da):
      collect(da)

def main():
  if argv[1:] == []:
    process(abspath(getcwd()))
    for e, ds in executables.items():
      if len(set(ds)) > 1:
        stderr.write('Warning: using {0} from {1}; ignoring {0} from {2}\n'.
            format(e, ds[0], ' and '.join(list(set(ds[1:])))))
    for d in getenv('PATH').split(pathsep):
      add_to_path(d)
  elif argv[1:] == ['-remove']:
    collect(abspath(getcwd()))
    for d in getenv('PATH').split(pathsep):
      if abspath(d) not in all_dirs:
        add_to_path(d)
  else:
    stderr.write('Error: Bad usage. I am just removing duplicates.\n')
    for d in getenv('PATH').split(pathsep):
      add_to_path(d)
  stdout.write(pathsep.join(new_path))

if __name__ == '__main__':
  main()
