#!/usr/bin/env python3
"""compare_runs.py CASE_A CASE_B [--files PATTERN]
Bit-for-bit comparison of two runs' CAM history files (e.g. SCAM on the container vs the full grid).
CASE_* are case names (archive under /glade/derecho/scratch/jet/archive/<case>/atm/hist, else
<case>/run) or directories.  Files are paired by the part of the name after the case name.
Prints, per file pair, every numeric variable that differs (max |A-B|), and TDIFF/QDIFF ranges.
"""
import argparse, glob, os, sys
import numpy as np
from netCDF4 import Dataset

SCR = '/glade/derecho/scratch/jet'
ap = argparse.ArgumentParser()
ap.add_argument('a'); ap.add_argument('b')
ap.add_argument('--files', default='.cam.h*.nc', help="file pattern after the case name (default .cam.h*.nc)")
args = ap.parse_args()

def histdir(c):
    if os.path.isdir(c):
        return c, os.path.basename(c.rstrip('/'))
    for d in (f'{SCR}/archive/{c}/atm/hist', f'{SCR}/{c}/run'):
        if glob.glob(f'{d}/{c}{args.files}'):
            return d, c
    sys.exit(f'no history files for {c}')

(da, ca), (db, cb) = histdir(args.a), histdir(args.b)
fa = {os.path.basename(f)[len(ca):]: f for f in sorted(glob.glob(f'{da}/{ca}{args.files}'))}
fb = {os.path.basename(f)[len(cb):]: f for f in sorted(glob.glob(f'{db}/{cb}{args.files}'))}
common = sorted(set(fa) & set(fb))
print(f'A: {da}\nB: {db}\nfile pairs: {len(common)}', ('(only in A: %s)' % sorted(set(fa)-set(fb))) if set(fa)-set(fb) else '',
      ('(only in B: %s)' % sorted(set(fb)-set(fa))) if set(fb)-set(fa) else '')
skip = {'date_written', 'time_written', 'nsteph'}
total_diff = 0
for k in common:
    with Dataset(fa[k]) as A, Dataset(fb[k]) as B:
        nvar = ndiff = 0
        diffs = []
        for v in A.variables:
            if v in skip or v not in B.variables:
                continue
            x, y = A[v], B[v]
            if x.dtype.kind not in 'fiu' or x.shape != y.shape:
                continue
            xa = np.asarray(x[:], dtype=np.float64); ya = np.asarray(y[:], dtype=np.float64)
            nvar += 1
            if not np.array_equal(xa, ya, equal_nan=True):
                ndiff += 1
                diffs.append((float(np.nanmax(np.abs(xa - ya))), v))
        for d in ('TDIFF', 'QDIFF'):
            for tag, F in (('A', A), ('B', B)):
                if d in F.variables:
                    z = np.asarray(F[d][:], dtype=np.float64)
                    print(f'  {k}: {d} in {tag}: min {np.nanmin(z):.6g} max {np.nanmax(z):.6g}')
        print(f'{k}: {nvar} numeric variables compared, {ndiff} differ')
        for m, v in sorted(diffs, reverse=True)[:15]:
            print(f'    {v:24s} max|A-B| = {m:.6g}')
        total_diff += ndiff
print('RESULT:', 'BIT-FOR-BIT' if total_diff == 0 and common else f'{total_diff} differing variables')
