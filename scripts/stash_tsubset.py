#!/usr/bin/env python3
"""SCAM-friendly stash, phase 1: time-subset native-ne30 (ncol) input files of a case.
Values are copied unchanged (bit-for-bit): only time samples outside [BEG, END] are dropped, keeping one
bracketing sample on each side.  Output is CDF5 in STASH.  Every copy is verified against its original.
Also writes STASH/user_nl_cam.stash with the case's namelist settings that reference subset files, with
the stash paths substituted (full lists for srf_emis_specifier / ext_frc_specifier and friends).

usage: stash_tsubset.py CASEDIR STASH BEG END [--min-times N] [--dry-run]
       BEG/END as YYYYMMDD, e.g. 19991201 20010131 for CYCLICAL year-2000 data
"""
import sys, os, re, glob, argparse
import numpy as np
from netCDF4 import Dataset

p = argparse.ArgumentParser()
p.add_argument('case'); p.add_argument('stash'); p.add_argument('beg', type=int); p.add_argument('end', type=int)
p.add_argument('--min-times', type=int, default=200, help='skip files with fewer time samples (default 200)')
p.add_argument('--dry-run', action='store_true')
a = p.parse_args()

atm_in = os.path.join(a.case, 'run', 'atm_in')
nl = open(atm_in).read() if os.path.isfile(atm_in) else ''
print('== time-handling settings in run/atm_in:')
for m in re.finditer(r'^\s*(\w+_(?:type|cycle_yr|fixed_ymd|fixed_tod))\s*=\s*(.*)$', nl, re.M):
    print('   %-32s = %s' % (m.group(1), m.group(2).strip()))

files = []
for lst in sorted(glob.glob(os.path.join(a.case, 'Buildconf', 'cam.input_data_list'))):
    for line in open(lst):
        if '=' in line:
            path = line.split('=', 1)[1].strip()
            if path.endswith('.nc') and os.path.isfile(path) and path not in files:
                files.append(path)

def subset_indices(date, beg, end):
    inside = np.nonzero((date >= beg) & (date <= end))[0]
    if inside.size == 0:
        return None
    i0, i1 = inside[0], inside[-1]
    return np.arange(max(i0 - 1, 0), min(i1 + 1, date.size - 1) + 1)

def copy_subset(src, dst, idx):
    with Dataset(src) as s, Dataset(dst, 'w', format='NETCDF3_64BIT_DATA') as d:
        d.setncatts({k: s.getncattr(k) for k in s.ncattrs()})
        d.setncattr('stash_note', 'time subset of %s: %d of %d samples (dates %d-%d plus brackets); values unchanged'
                    % (os.path.basename(src), idx.size, len(s.dimensions['time']), a.beg, a.end))
        for name, dim in s.dimensions.items():
            d.createDimension(name, None if dim.isunlimited() else (idx.size if name == 'time' else len(dim)))
        for name, v in s.variables.items():
            fill = v.getncattr('_FillValue') if '_FillValue' in v.ncattrs() else None
            o = d.createVariable(name, v.dtype, v.dimensions, fill_value=fill)
            o.setncatts({k: v.getncattr(k) for k in v.ncattrs() if k != '_FillValue'})
            v.set_auto_maskandscale(False); o.set_auto_maskandscale(False)
            if 'time' in v.dimensions:
                ax = v.dimensions.index('time')
                for j, k in enumerate(idx):
                    sl_s = [slice(None)] * v.ndim; sl_s[ax] = k
                    sl_d = [slice(None)] * v.ndim; sl_d[ax] = j
                    o[tuple(sl_d)] = v[tuple(sl_s)]
            else:
                o[...] = v[...]

def verify(src, dst, idx):
    with Dataset(src) as s, Dataset(dst) as d:
        for name, v in s.variables.items():
            w = d.variables[name]; v.set_auto_maskandscale(False); w.set_auto_maskandscale(False)
            if 'time' in v.dimensions:
                ax = v.dimensions.index('time')
                for j in sorted({0, idx.size // 2, idx.size - 1}):
                    sl_s = [slice(None)] * v.ndim; sl_s[ax] = idx[j]
                    sl_d = [slice(None)] * v.ndim; sl_d[ax] = j
                    x, y = np.asarray(v[tuple(sl_s)]), np.asarray(w[tuple(sl_d)])
                    same = np.array_equal(x, y, equal_nan=True) if x.dtype.kind == 'f' else np.array_equal(x, y)
                    if not same: return 'DIFF in %s at sample %d' % (name, j)
            else:
                x, y = np.asarray(v[...]), np.asarray(w[...])
                same = np.array_equal(x, y, equal_nan=True) if x.dtype.kind == 'f' else np.array_equal(x, y)
                if not same: return 'DIFF in %s' % name
    return 'identical'

os.makedirs(a.stash, exist_ok=True)
done = {}
print('== files')
for f in files:
    with Dataset(f) as s:
        if 'ncol' not in s.dimensions or 'time' not in s.dimensions or 'date' not in s.variables:
            continue
        nt = len(s.dimensions['time'])
        if nt < a.min_times:
            print('   skip (%d samples)  %s' % (nt, os.path.basename(f))); continue
        date = np.asarray(s.variables['date'][:]).astype(np.int64)
    idx = subset_indices(date, a.beg, a.end)
    if idx is None:
        print('   SKIP: no samples in window  %s' % os.path.basename(f)); continue
    out = os.path.join(a.stash, os.path.basename(f).replace('.nc', '_t%d-%d.nc' % (a.beg, a.end)))
    print('   %4d of %5d samples (%d..%d)  %s' % (idx.size, nt, date[idx[0]], date[idx[-1]], os.path.basename(out)))
    if a.dry_run: continue
    if os.path.exists(out):
        print('      exists, verifying only'); 
    else:
        copy_subset(f, out, idx)
    r = verify(f, out, idx); print('      check: %s' % r)
    if r == 'identical': done[f] = out

if done and nl:
    lines = nl.split('\n'); keep = []; i = 0
    while i < len(lines):
        m = re.match(r'^\s*(\w+)\s*=', lines[i])
        if m:
            j = i + 1
            while j < len(lines) and not re.match(r'^\s*(\w+\s*=|/)', lines[j]): j += 1
            block = '\n'.join(lines[i:j])
            if any(src in block for src in done):
                for src, dst in done.items(): block = block.replace(src, dst)
                keep.append(block.strip())
            i = j
        else:
            i += 1
    nlout = os.path.join(a.stash, 'user_nl_cam.stash')
    open(nlout, 'w').write('\n'.join(keep) + '\n')
    print('== %d namelist settings rewritten -> %s' % (len(keep), nlout))
print('== %d files subset and verified identical' % len(done))
