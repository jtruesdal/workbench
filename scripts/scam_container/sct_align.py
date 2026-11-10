#!/usr/bin/env python3
"""sct_align.py TESTDIR [--vars V1,V2,...]
Line up an SCT test's SCAM run with its 3D run at the SCAM column, step by step.
- SCAM history: TESTDIR/run/case2run/*.cam.h*.nc ; 3D history: TESTDIR/run/*.cam.h*.nc
- the 3D column is the one nearest the SCAM file's lat/lon
- every numeric variable present in both, at matching time values, is compared exactly
Prints the SCAM TDIFF/QDIFF per step, then each differing variable with the first time step it differs
and its max |SCAM-3D| there, sorted by first difference; then the variables that agree.
"""
import argparse, glob, os, sys
import numpy as np
from netCDF4 import Dataset

ap = argparse.ArgumentParser()
ap.add_argument('testdir')
ap.add_argument('--vars', default='')
a = ap.parse_args()
run = os.path.join(a.testdir, 'run')
scam_files = sorted(glob.glob(os.path.join(run, 'case2run', '*.cam.h*.nc')))
d3_files = sorted(glob.glob(os.path.join(run, '*.cam.h*.nc')))
if not scam_files or not d3_files:
    sys.exit('need SCAM (run/case2run/*.cam.h*.nc) and 3D (run/*.cam.h*.nc) history; found %d / %d'
             % (len(scam_files), len(d3_files)))
only = set(v for v in a.vars.split(',') if v)

def load(files, col=None):
    """{var: {time: 1-D array over levels (or scalar array)}} plus lat/lon of the column"""
    out, lat, lon = {}, None, None
    for f in files:
        with Dataset(f) as d:
            if 'time' not in d.variables:
                continue
            t = np.round(np.asarray(d['time'][:], np.float64), 8)
            hdim = 'ncol' if 'ncol' in d.dimensions else ('ncol_d' if 'ncol_d' in d.dimensions else None)
            if hdim is None:
                continue
            la = np.asarray(d['lat'][:], np.float64) if 'lat' in d.variables else None
            lo = np.asarray(d['lon'][:], np.float64) if 'lon' in d.variables else None
            if col is None:
                i = 0
                if la is not None and la.size == 1:
                    lat, lon = float(la.ravel()[0]), float(lo.ravel()[0])
            else:
                i = int(np.argmin(np.abs(la - col[0]) + np.abs(((lo - col[1] + 180) % 360) - 180)))
                lat, lon = float(la[i]), float(lo[i])
            for name, v in d.variables.items():
                if only and name not in only:
                    continue
                if v.dtype.kind != 'f' or not v.dimensions or v.dimensions[0] != 'time' or hdim not in v.dimensions:
                    continue
                x = np.take(np.asarray(v[:], np.float64), i, axis=v.dimensions.index(hdim))
                for k, tt in enumerate(t):
                    out.setdefault(name, {})[tt] = x[k]
    return out, lat, lon

s, slat, slon = load(scam_files)
if slat is None:
    sys.exit('SCAM history has no single-column lat/lon')
g, glat, glon = load(d3_files, (slat, slon))
print('SCAM column lat/lon %.6f %.6f   3D column lat/lon %.6f %.6f' % (slat, slon, glat, glon))
print('SCAM files: %d   3D files: %d' % (len(scam_files), len(d3_files)))

for dv in ('TDIFF', 'QDIFF'):
    if dv in s:
        print('%s max|.| per step:' % dv, ' '.join('%.2e' % float(np.max(np.abs(s[dv][t]))) for t in sorted(s[dv])))

# match names case-insensitively: the CAMIOP file uses lower case (t, q, ps, ...)
gl = {}
for k in g:
    gl.setdefault(k.lower(), k)
pairs = [(n, gl[n.lower()]) for n in sorted(s) if n.lower() in gl]

# TDIFF/QDIFF profile at the first step, with the SCAM and IOP values behind them
for dv, sv in (('TDIFF', 'T'), ('QDIFF', 'Q')):
    if dv in s and sv in s and sv.lower() in gl:
        t0 = sorted(s[dv])[0]
        gname = gl[sv.lower()]
        prof = np.atleast_1d(s[dv][t0]); sval = np.atleast_1d(s[sv][t0])
        gval = np.atleast_1d(g[gname][t0]) if t0 in g[gname] else None
        print('\n%s at the first step (time %.6f), by level: %s, SCAM %s, 3D/IOP %s' % (dv, t0, dv, sv, gname))
        for k in range(prof.size):
            print('   lev %2d  %12.5e  %14.7e  %s' % (k + 1, prof[k], sval[k] if k < sval.size else np.nan,
                  ('%14.7e' % gval[k]) if gval is not None and k < gval.size else '-'))

diff, same = [], []
for name, gname in pairs:
    g[name] = g[gname]
for name, _ in pairs:
    times = sorted(set(s[name]) & set(g[name]))
    if not times:
        continue
    first = None
    for t in times:
        if not np.array_equal(s[name][t], g[name][t], equal_nan=True):
            first = (t, float(np.nanmax(np.abs(s[name][t] - g[name][t]))))
            break
    (diff if first else same).append((name, first, len(times)))
print('\ncommon variables: %d   differing: %d   identical: %d' % (len(diff) + len(same), len(diff), len(same)))
tstep = sorted(set().union(*[set(s[n]) & set(g[n]) for n, _, _ in diff + same])) if diff + same else []
for name, (t, m), n in sorted(diff, key=lambda x: (x[1][0], x[0])):
    print('  DIFF  %-14s first at time %.6f (step %d of %d)  max|SCAM-3D| = %.3e'
          % (name, t, tstep.index(t), n, m))
print('  identical:', ' '.join(n for n, _, _ in same))
