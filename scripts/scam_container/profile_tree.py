#!/usr/bin/env python3
"""profile_tree.py FILE [REGION ...] [--depth N] [--min SECONDS]
Print timer regions and everything nested under them from a CESM ESMF profile summary
(timing/cesm.ESMF_Profile.summary.*), with count and mean seconds, indented by depth.
Default regions: cam_init_phys_init, cam_init_dyn_init, stepon_run1, phys_run1, stepon_run3.
FILE may be a case directory; then its newest profile summary is used.
"""
import argparse, glob, os, re

ap = argparse.ArgumentParser()
ap.add_argument('file')
ap.add_argument('regions', nargs='*')
ap.add_argument('--depth', type=int, default=3, help='levels below each region (default 3)')
ap.add_argument('--min', type=float, default=0.05, help='hide regions under this many seconds')
a = ap.parse_args()
f = a.file
if os.path.isdir(f):
    c = sorted(glob.glob(os.path.join(f, 'timing', 'cesm.ESMF_Profile.summary.*')), key=os.path.getmtime)
    f = c[-1]
regions = a.regions or ['cam_init_phys_init', 'cam_init_dyn_init', 'stepon_run1', 'phys_run1', 'stepon_run3']
num = re.compile(r'^-?\d+(\.\d+)?([eE][-+]?\d+)?$')

rows = []                                     # (indent, name, count, mean)
for line in open(f):
    if not line.strip() or not line.startswith(' ') and not line.startswith('['):
        continue
    tok = line.split()
    tail = 0
    while tail < len(tok) and num.match(tok[-1 - tail]):
        tail += 1
    if tail < 5 or tail == len(tok):
        continue
    nums = tok[len(tok) - tail:]
    name = ' '.join(tok[:len(tok) - tail])
    indent = len(line) - len(line.lstrip(' '))
    rows.append((indent, name, nums[-6], float(nums[-5])))

print('profile:', f)
for r in regions:
    hits = [i for i, x in enumerate(rows) if x[1] == r]
    if not hits:
        print('\n== %s: not found' % r); continue
    for i in hits:
        ind0 = rows[i][0]
        print('\n== %s  (count %s, mean %.2f s)' % (r, rows[i][2], rows[i][3]))
        levels = sorted({x[0] for x in rows if x[0] > ind0})
        for x in rows[i + 1:]:
            if x[0] <= ind0:
                break
            depth = levels.index(x[0]) + 1 if x[0] in levels else 99
            if depth <= a.depth and x[3] >= a.min:
                print('   %s%-40s %6s %10.3f' % ('  ' * (depth - 1), x[1], x[2], x[3]))
