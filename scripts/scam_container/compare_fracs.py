#!/usr/bin/env python3
"""compare_fracs.py -- land/ocean fractions at chosen columns: domain file vs what the 3D run used.

Sources (defaults are the sctc01 SCT test on Derecho):
  domain  : single_column_lnd_domainfile (xc, yc, frac, mask)
  ctsm    : the 3D run's CTSM land fraction cache  run/init_generated_files/ctsm_landfrac*.nc
  cpl     : the 3D run's mediator history          run/*.cpl.hi.*.nc   (all variables with 'frac' or 'omask')
  iop     : the CAMIOP file (lat/lon) to locate the ne30 columns

usage: compare_fracs.py [TESTDIR] [--domain FILE]
"""
import argparse, glob, os, sys
import numpy as np
from netCDF4 import Dataset

SITES = {'Manus': (-2.06, 147.43), 'Nauru': (-0.521, 166.916), 'Darwin': (-12.425, 130.892),
         'Barrow': (71.323, 203.389), 'SGP': (36.6336386049331, 263.170820393250)}
TD = ('/glade/derecho/scratch/jet/SCT_D_Ln48.ne30_ne30_mg17.F2000climo_SROF.'
      'derecho_intel.cam-scm_prep_ERAnudge_derecho.sctc01')
DOM = '/glade/campaign/cesm/cesmdata/inputdata/share/domains/domain.lnd.ne30_gx1v7.171003.nc'

ap = argparse.ArgumentParser()
ap.add_argument('testdir', nargs='?', default=TD)
ap.add_argument('--domain', default=DOM)
a = ap.parse_args()
run = os.path.join(a.testdir, 'run')

def first(pattern):
    f = sorted(glob.glob(pattern))
    return f[0] if f else None

def nearest(lat, lon, la, lo):
    d = np.abs(((lon - lo + 180.0) % 360.0) - 180.0) * np.cos(np.radians(la)) + np.abs(lat - la)
    return int(np.argmin(d))

iop = first(os.path.join(run, '*.cam.h1i.*.nc'))
if not iop: sys.exit('no CAMIOP h1i file in ' + run)
with Dataset(iop) as d:
    lat = np.asarray(d['lat'][:], np.float64); lon = np.asarray(d['lon'][:], np.float64)
print('IOP   :', iop, ' columns:', lat.size)

with Dataset(a.domain) as d:
    xc = np.asarray(d['xc'][:], np.float64).reshape(-1); yc = np.asarray(d['yc'][:], np.float64).reshape(-1)
    dfrac = np.asarray(d['frac'][:], np.float64).reshape(-1); dmask = np.asarray(d['mask'][:]).reshape(-1)
print('domain:', a.domain, ' points:', xc.size)

ctsm = first(os.path.join(run, 'init_generated_files', 'ctsm_landfrac*.nc'))
cvars = {}
if ctsm:
    with Dataset(ctsm) as d:
        for k, v in d.variables.items():
            if v.size == lat.size: cvars[k] = np.asarray(v[:], np.float64).reshape(-1)
print('ctsm  :', ctsm or 'not found', ' fields:', ', '.join(cvars) or '-')

cpl = first(os.path.join(run, '*.cpl.hi.*.nc'))
pvars = {}
if cpl:
    with Dataset(cpl) as d:
        for k, v in d.variables.items():
            kl = k.lower()
            if ('frac' in kl or 'omask' in kl or 'lfrin' in kl) and v.size % lat.size == 0 and v.size >= lat.size:
                x = np.asarray(v[:], np.float64).reshape(-1)
                pvars[k] = x[-lat.size:]          # last time sample on a 48602-point grid
print('cpl   :', cpl or 'not found', ' fields on this grid:', len(pvars))

for name, (la, lo) in SITES.items():
    i = nearest(lat, lon, la, lo)
    j = nearest(yc, xc, lat[i], lon[i])
    print('\n== %s: ne30 column %d at lat %.6f lon %.6f' % (name, i, lat[i], lon[i]))
    print('   domain point %d at yc %.6f xc %.6f (same index: %s)' % (j, yc[j], xc[j], i == j))
    print('   domain   frac = %.17g  mask = %d' % (dfrac[j], dmask[j]))
    for k, x in cvars.items():
        print('   ctsm     %-22s = %.17g' % (k, x[i]))
    for k, x in sorted(pvars.items()):
        print('   cpl      %-22s = %.17g' % (k, x[i]))
