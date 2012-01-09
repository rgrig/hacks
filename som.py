#!/usr/bin/env python3
# Sort Ocaml variant Pattern

import sys

current = []
blocks = [current]
for line in sys.stdin:
  if line.strip().startswith('|'):
    current = []
    blocks.append(current)
  current.append(line)
blocks.sort()
for b in blocks:
  for line in b:
    sys.stdout.write(line)
