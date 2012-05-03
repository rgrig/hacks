#!/usr/bin/env python3

import os
import subprocess

from fnmatch import fnmatch

unzipped = set()
todo = True

def unzip(p):
  global todo, unzipped
  for f in os.listdir(p):
    pf = os.path.join(p, f)
    try:
      os.chdir(f)
      unzip(pf)
      os.chdir(p)
    except OSError:
      pass # not a directory, probably
    if (fnmatch(f, '*.jar') or fnmatch(f, '*.zip')) and pf not in unzipped:
      subprocess.call(['unzip', '-o', f])
      unzipped.add(pf)
      todo = True

while todo:
  todo = False
  unzip(os.getcwd())

print('Done:')
u = list(unzipped)
u.sort()
for f in u:
  print('  {0}'.format(f))
