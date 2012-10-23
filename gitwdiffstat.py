#!/usr/bin/env python3

# Does (roughly) the same as
#   git diff $1 --word-diff=porcelain | grep "^+" | wc -w
# but with slightly nicer output

from sys import argv
from subprocess import CalledProcessError, check_output

try:
  added = 0
  removed = 0
  command = ['git', 'diff'] + argv[1:] + ['--word-diff=porcelain']
  for line in check_output(command, universal_newlines=True).splitlines():
    if line[0:1] == '+' and line[0:3] != '+++':
      added += len(line.split())
    if line[0:1] == '-' and line[0:3] != '---':
      removed += len(line.split())
  print(' {0} insertion(+), {1} deletion(-)'.format(added, removed))
except CalledProcessError:
  print('Error while running git.')
