#!/usr/bin/env python3
"""iop_profile.py TESTDIR
First-step comparison of an SCT test's SCAM run with its CAMIOP file, level by level.
The CAMIOP file has two horizontal dimensions: physics columns (ncol: lat/lon) and dynamics GLL
columns (ncol_d: lat_d/lon_d; t, q, u, v, Ps live here).  The column is located separately in
each, and the script reports whether the two orderings agree.
"""
import glob, os, sys
import numpy as np
from netCDF4 import Dataset
td = sys.argv[1]
iop = sorted(glob.glob(os.path.join(td, 'run', '*.cam.h1i.*.nc')))
iop = [f for f in iop if '/case2run/' not in f][0]
scam = sorted(glob.glob(os.path.join(td, 'run', 'case2run', '*.cam.h*.nc')))
near = lambda la, lo, y, x: int(np.argmin(np.abs(la - y) + np.abs(((lo - x + 180) % 360) - 180)))
S = {}
for f in scam:
    with Dataset(f) as d:
        if 'lat' in d.variables and 'slat' not in S:
            S['slat'] = float(np.asarray(d['lat'][:]).ravel()[0]); S['slon'] = float(np.asarray(d['lon'][:]).ravel()[0])
        for v in ('T', 'Q', 'PS', 'TDIFF', 'QDIFF', 'TS'):
            if v in d.variables and v not in S:
                S[v] = np.asarray(d[v][0], np.float64).ravel()
print('SCAM column %.6f %.6f   (files: %d)' % (S['slat'], S['slon'], len(scam)))
with Dataset(iop) as d:
    la, lo = np.asarray(d['lat'][:], np.float64), np.asarray(d['lon'][:], np.float64)
    lad, lod = np.asarray(d['lat_d'][:], np.float64), np.asarray(d['lon_d'][:], np.float64)
    i, k = near(la, lo, S['slat'], S['slon']), near(lad, lod, S['slat'], S['slon'])
    print('IOP physics column  (ncol)   index %4d at %.6f %.6f' % (i + 1, la[i], lo[i]))
    print('IOP dynamics column (ncol_d) index %4d at %.6f %.6f' % (k + 1, lad[k], lod[k]))
    same = la.size == lad.size and np.array_equal(la, lad) and np.array_equal(lo, lod)
    print('ncol and ncol_d orderings identical:', same)
    if not same and la.size == lad.size:
        print('   at ncol_d index %d the physics coordinates are %.6f %.6f' % (i + 1, lad[i], lod[i]))
    t = np.asarray(d['t'][0], np.float64)[:, k]; q = np.asarray(d['q'][0], np.float64)[:, k]
    tw = np.asarray(d['t'][0], np.float64)[:, i]            # what an ncol index would read
    ps = float(np.asarray(d['Ps'][0], np.float64)[k]); tg = float(np.asarray(d['Tg'][0], np.float64)[i])
print('PS  SCAM %r   IOP %r' % (float(S['PS'][0]) if 'PS' in S else None, ps))
print('TS  SCAM %r   IOP Tg %r' % (float(S['TS'][0]) if 'TS' in S else None, tg))
print(' lev   SCAM T        IOP t(ncol_d)   IOP t(at ncol index)   TDIFF        SCAM Q       IOP q')
for l in range(t.size):
    print(' %3d  %12.6f  %12.6f  %12.6f  %12.5e  %12.5e  %12.5e' % (
        l + 1, S['T'][l], t[l], tw[l], S['TDIFF'][l] if 'TDIFF' in S else np.nan, S['Q'][l], q[l]))
