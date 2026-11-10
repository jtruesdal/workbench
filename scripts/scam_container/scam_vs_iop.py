#!/usr/bin/env python3
"""scam_vs_iop.py CASE [CASE ...]
Quick check of a SCAM run against its CAMIOP file: PHIS of the SCAM column vs the IOP column
(first time), and TDIFF/QDIFF max |.| per step.  CASE: a case name under
/glade/campaign/cgd/amp/jet/cases; history from /glade/derecho/scratch/jet/archive/<case>/atm/hist
(else the run directory); the IOP file from the case's CaseDocs/atm_in.
"""
import glob, os, re, sys
import numpy as np
from netCDF4 import Dataset
CASES = '/glade/campaign/cgd/amp/jet/cases'
SCR = '/glade/derecho/scratch/jet'
for case in sys.argv[1:]:
    atm_in = open(os.path.join(CASES, case, 'CaseDocs', 'atm_in')).read()
    iop = re.search(r"^\s*iopfile\s*=\s*'([^']+)'", atm_in, re.M).group(1)
    hist = sorted(glob.glob(f'{SCR}/archive/{case}/atm/hist/{case}.cam.h*.nc')) or \
           sorted(glob.glob(f'{SCR}/{case}/run/{case}.cam.h*.nc'))
    print('==', case)
    if not hist:
        print('   no history yet'); continue
    lat = lon = phis_s = td = qd = None
    for h in hist:                      # PHIS from the first file that has it, TDIFF/QDIFF likewise
        with Dataset(h) as d:
            if lat is None and 'lat' in d.variables:
                lat = float(np.asarray(d['lat'][:]).ravel()[0]); lon = float(np.asarray(d['lon'][:]).ravel()[0])
            if phis_s is None and 'PHIS' in d.variables:
                phis_s = float(np.asarray(d['PHIS'][0]).ravel()[0])
            if td is None and 'TDIFF' in d.variables:
                td = np.asarray(d['TDIFF'][:]); print('   TDIFF/QDIFF from', os.path.basename(h))
            if qd is None and 'QDIFF' in d.variables:
                qd = np.asarray(d['QDIFF'][:])
    with Dataset(iop) as d:
        la = np.asarray(d['lat'][:], np.float64); lo = np.asarray(d['lon'][:], np.float64)
        i = int(np.argmin(np.abs(la - lat) + np.abs(((lo - lon + 180) % 360) - 180)))
        v = d['PHIS'] if 'PHIS' in d.variables else None
        phis_i = float(np.asarray(v[0, i] if v.ndim == 2 else v[i])) if v is not None else None
    print('   column %.6f %.6f   IOP column %d at %.6f %.6f' % (lat, lon, i + 1, la[i], lo[i]))
    print('   PHIS  SCAM %r   IOP %r   %s' % (phis_s, phis_i, 'SAME' if phis_s == phis_i else 'DIFFERENT'))
    if td is not None:
        print('   TDIFF max|.| per step:', ' '.join('%.2e' % float(np.max(np.abs(x))) for x in td))
        print('   TDIFF all zero:', bool(np.all(td == 0)))
    if qd is not None:
        print('   QDIFF max|.| per step:', ' '.join('%.2e' % float(np.max(np.abs(x))) for x in qd))
        print('   QDIFF all zero:', bool(np.all(qd == 0)))
