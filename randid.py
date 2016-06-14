#!/usr/bin/env python3

from random import choice
from shutil import get_terminal_size
from string import ascii_lowercase
import os
import sys

n = get_terminal_size(fallback=(80,25)).columns
n = max(1, n - 1)
id = ''.join(choice(ascii_lowercase) for _ in range(n))
sys.stdout.write('{}\n'.format(id))
