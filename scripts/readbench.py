#!/usr/bin/env python3
"""Time netCDF reads the way a single-column run uses them (read-only).
For each file: time to open, to read one column of the given variables, and to read the whole fields.
usage: readbench.py FILE [VAR ...] [--col N]
  With no VARs: T,Q,U,V,PS if present (ERA5 nudging files), else the first variable with an ncol dimension.
Note: run each file cold (first read) for meaningful timings; repeated reads hit the OS cache.
Findings 2026-11-04 (Derecho, ERA5 nudging netCDF-4, contiguous, uncompressed): open 0.10 s, one column of
T,Q,U,V,PS 0.33 s cold -> file reads were not the SCAM bottleneck."""
import sys, time, argparse
from netCDF4 import Dataset
p = argparse.ArgumentParser(); p.add_argument('file'); p.add_argument('vars', nargs='*'); p.add_argument('--col', type=int, default=20000)
a = p.parse_args()
t0 = time.time(); ds = Dataset(a.file); t1 = time.time()
names = a.vars or [n for n in ('T', 'Q', 'U', 'V', 'PS') if n in ds.variables] or \
        [n for n, v in ds.variables.items() if v.ndim >= 2 and 'ncol' in v.dimensions][:1]
print('file:', a.file.split('/')[-1], '  format:', ds.file_format)
print('   open:          %.3f s' % (t1 - t0))
t0 = time.time()
for n in names:
    v = ds.variables[n]; ax = v.dimensions.index('ncol')
    sl = [0 if d in ('time',) else slice(None) for d in v.dimensions]; sl[ax] = a.col
    _ = v[tuple(sl)]
t1 = time.time(); print('   one column:    %.3f s  (%s, col %d)' % (t1 - t0, ','.join(names), a.col))
t0 = time.time()
for n in names:
    v = ds.variables[n]; _ = v[0] if 'time' in v.dimensions else v[...]
t1 = time.time(); print('   whole fields:  %.3f s' % (t1 - t0))
ds.close()
