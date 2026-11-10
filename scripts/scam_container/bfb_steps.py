#!/usr/bin/env python3
"""bfb_steps.py [CASE] -- TDIFF/QDIFF max |.| per step from a SCAM case's tape-2 (h1i) history in its
run directory (cases run with DOUT_S=FALSE).  Default case BFB.barrow.scam.01."""
import glob, sys
import numpy as np
from netCDF4 import Dataset
case = sys.argv[1] if len(sys.argv) > 1 else 'BFB.barrow.scam.01'
pat = '/glade/derecho/scratch/jet/' + case + '/run/' + case + '.cam.h1i.*.nc'
for f in sorted(glob.glob(pat)):
    with Dataset(f) as d:
        t = np.asarray(d['TDIFF'][:])
        q = np.asarray(d['QDIFF'][:])
        for s in range(t.shape[0]):
            print(f.split('/')[-1], 'step', s, 'max TDIFF', abs(t[s]).max(), 'max QDIFF', abs(q[s]).max())
