#!/usr/bin/env python3
"""sct_diffs.py ID [SCRATCH] -- max |TDIFF| and |QDIFF| over all levels and steps for every SCT test
with test id ID (the SCAM half's cam h1i file).  SCRATCH defaults to Derecho's
/glade/derecho/scratch/jet; on Izumi use /scratch/cluster/jet."""
import glob, sys
import numpy as np
from netCDF4 import Dataset
tid = sys.argv[1] if len(sys.argv) > 1 else 'sctx02'
scr = sys.argv[2] if len(sys.argv) > 2 else '/glade/derecho/scratch/jet'
files = sorted(glob.glob(scr + '/SCT_*.' + tid + '/run/case2run/*.cam.h1i.*0000.nc'))
if not files:
    print('no SCAM h1i files yet for', tid)
for f in files:
    with Dataset(f) as d:
        t = np.abs(np.asarray(d['TDIFF'][:])).max()
        q = np.abs(np.asarray(d['QDIFF'][:])).max()
    print(f.split('/')[-4], 'max TDIFF', t, 'max QDIFF', q)
