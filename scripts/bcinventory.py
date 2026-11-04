#!/usr/bin/env python3
"""Inventory of a CESM case's netCDF input files for a SCAM-friendly stash (read-only).
usage: bcinventory.py CASEDIR [MIN_MB]   -> table: grid, ntime, first/last date, MB, namelist variable, file"""
import sys, os, glob
from netCDF4 import Dataset
case = sys.argv[1]; minmb = float(sys.argv[2]) if len(sys.argv) > 2 else 50
rows = []
for lst in sorted(glob.glob(os.path.join(case, 'Buildconf', '*.input_data_list'))):
    comp = os.path.basename(lst).split('.')[0]
    for line in open(lst):
        if '=' not in line: continue
        var, path = [s.strip() for s in line.split('=', 1)]
        if not path.endswith('.nc') or not os.path.isfile(path): continue
        mb = os.path.getsize(path) / 1e6
        if mb < minmb: continue
        try:
            ds = Dataset(path); dims = ds.dimensions
            if 'ncol' in dims: grid = 'ncol%d' % len(dims['ncol'])
            elif 'lat' in dims and 'lon' in dims: grid = 'latlon%dx%d' % (len(dims['lat']), len(dims['lon']))
            elif 'lat' in dims: grid = 'zm%d' % len(dims['lat'])
            else: grid = 'other'
            nt = len(dims['time']) if 'time' in dims else 0
            d0 = d1 = ''
            if 'date' in ds.variables and nt:
                d = ds.variables['date']; d0, d1 = str(int(d[0])), str(int(d[-1]))
            elif 'time' in ds.variables and nt:
                t = ds.variables['time']; d0, d1 = '%g' % t[0], '%g %s' % (t[-1], getattr(t, 'units', ''))
            ds.close()
        except Exception as e:
            grid, nt, d0, d1 = 'ERR', 0, '', str(e)[:30]
        rows.append((mb, comp, var, grid, nt, d0, d1, os.path.basename(path)))
rows.sort(reverse=True)
print('%8s %-5s %-14s %6s %-10s %-24s %-32s %s' % ('MB', 'comp', 'grid', 'ntime', 'first', 'last', 'namelist var', 'file'))
for mb, comp, var, grid, nt, d0, d1, f in rows:
    print('%8.0f %-5s %-14s %6d %-10s %-24s %-32s %s' % (mb, comp, grid, nt, d0, d1[:24], var[:32], f))
print('%d files >= %g MB, total %.1f GB' % (len(rows), minmb, sum(r[0] for r in rows) / 1e3))
