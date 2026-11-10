#!/usr/bin/env python3
"""cmp_pair.py [CASE3D CASESCAM]
Step-by-step comparison of a SCAM run with its 3D run at the SCAM column, for files written by
bfb_rerun.sh (no archiving: both run directories):
  * coupler history (cpl.hi.*), every step: all mediator fields (fractions, imports, exports)
  * CAM history files present in both cases with the same tape (h0i..h5i)
Files are paired by their date-seconds; time samples within a CAM file by time value.  For each
field, prints the first step where SCAM and 3D differ; fraction fields are listed first.
"""
import glob, os, re, sys
import numpy as np
from netCDF4 import Dataset
SCR = '/glade/derecho/scratch/jet'
c3, cs = (sys.argv[1:3] if len(sys.argv) > 2 else ('BFB.barrow.3d.01', 'BFB.barrow.scam.01'))
r3, rs = f'{SCR}/{c3}/run', f'{SCR}/{cs}/run'

# SCAM column from a SCAM CAM file, 3D column index from a 3D CAM file
sf = sorted(glob.glob(f'{rs}/{cs}.cam.h*.nc'))[0]
with Dataset(sf) as d:
    slat = float(np.asarray(d['lat'][:]).ravel()[0]); slon = float(np.asarray(d['lon'][:]).ravel()[0])
gf = sorted(glob.glob(f'{r3}/{c3}.cam.h3i.*.nc') or glob.glob(f'{r3}/{c3}.cam.h0i.*.nc'))[0]
with Dataset(gf) as d:
    la = np.asarray(d['lat'][:], np.float64); lo = np.asarray(d['lon'][:], np.float64)
col = int(np.argmin(np.abs(la - slat) + np.abs(((lo - slon + 180) % 360) - 180)))
ncol3 = la.size
print('SCAM column %.6f %.6f   3D column index %d (1-based) at %.6f %.6f' % (slat, slon, col + 1, la[col], lo[col]))

def at_col(v):
    x = np.asarray(v[:], np.float64)
    if x.size % ncol3 == 0 and x.size >= ncol3 and ncol3 > 1:
        return x.reshape(-1, ncol3)[:, col]            # leading dims (time, lev) x columns
    return None

def single(v):
    return np.asarray(v[:], np.float64).ravel()

first = {}        # field -> (step label, max abs diff)
def compare(f3, fs, label):
    with Dataset(f3) as a, Dataset(fs) as b:
        for name, v in b.variables.items():
            if name not in a.variables or v.dtype.kind != 'f' or name in ('time', 'time_bnds', 'lat', 'lon'):
                continue
            x3 = at_col(a[name]); xs = single(v)
            if x3 is None or x3.size != xs.size:
                continue
            if not np.array_equal(x3, xs, equal_nan=True) and name not in first:
                first[name] = (label, float(np.nanmax(np.abs(x3 - xs))))
            first.setdefault('_compared_' + name, None)

suffix = lambda f: re.search(r'(\d{4}-\d\d-\d\d-\d{5})\.nc$', f).group(1)
# coupler history, one file per step
cp3 = {suffix(f): f for f in glob.glob(f'{r3}/{c3}.cpl.hi.*.nc')}
cps = {suffix(f): f for f in glob.glob(f'{rs}/{cs}.cpl.hi.*.nc')}
steps = sorted(set(cp3) & set(cps))
print('coupler history: %d steps in common (%s .. %s)' % (len(steps), steps[0] if steps else '-', steps[-1] if steps else '-'))
for s in steps:
    compare(cp3[s], cps[s], 'cpl ' + s)
# CAM tape 4 (h3i): 3D one file with all steps, SCAM one file per step -> compare by time value
f3 = sorted(glob.glob(f'{r3}/{c3}.cam.h3i.*.nc'))
fs = sorted(glob.glob(f'{rs}/{cs}.cam.h3i.*.nc'))
if f3 and fs:
    with Dataset(f3[0]) as a:
        t3 = list(np.round(np.asarray(a['time'][:], np.float64), 8))
        for f in fs:
            with Dataset(f) as b:
                ts = float(np.round(np.asarray(b['time'][:], np.float64)[0], 8))
                if ts not in t3:
                    continue
                k = t3.index(ts)
                for name, v in b.variables.items():
                    if name not in a.variables or v.dtype.kind != 'f' or 'time' not in v.dimensions[:1]:
                        continue
                    x3 = np.asarray(a[name][k], np.float64)
                    x3 = x3.reshape(-1, ncol3)[:, col] if x3.size % ncol3 == 0 and x3.size >= ncol3 else None
                    xs = np.asarray(v[0], np.float64).ravel()
                    if x3 is None or x3.size != xs.size:
                        continue
                    key = 'CAM ' + name
                    first.setdefault('_compared_' + key, None)
                    if not np.array_equal(x3, xs, equal_nan=True) and key not in first:
                        first[key] = ('time %.6f (step %d)' % (ts, k), float(np.nanmax(np.abs(x3 - xs))))
compared = [k[len('_compared_'):] for k in first if k.startswith('_compared_')]
diff = {k: v for k, v in first.items() if not k.startswith('_compared_')}
print('fields compared: %d   differing: %d' % (len(compared), len(diff)))
isfrac = lambda n: ('frac' in n.lower() or 'mask' in n.lower() or 'frad' in n.lower())
for name, (lab, m) in sorted(diff.items(), key=lambda kv: (not isfrac(kv[0]), kv[1][0], kv[0])):
    print('  DIFF %-32s first at %-24s max|3D-SCAM| = %.3e' % (name, lab, m))
same_frac = sorted(n for n in compared if isfrac(n) and n not in diff)
print('  fraction/mask fields identical at every step:', ' '.join(same_frac) or '-')
