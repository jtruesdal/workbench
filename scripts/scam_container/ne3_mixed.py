#!/usr/bin/env python3
"""ne3_mixed.py CASEDIR
List the grid points of a case's atmosphere mesh that are partly land and partly ocean, with
their land fraction computed as DOCN/CTSM do (mask mesh -> atmosphere mesh, conservative,
DSTAREA, mask value 0 excluded; land = 1 - ocean, < 0.001 -> 0).  Points poleward of 50 degrees
(sea-ice candidates in January) are marked.  Meshes are taken from the case (xmlquery).
"""
import subprocess, sys
import numpy as np
try:
    import esmpy as E
except ImportError:
    import ESMF as E

case = sys.argv[1]
q = lambda v: subprocess.run(['./xmlquery', '--value', v], cwd=case, capture_output=True, text=True).stdout.strip()
atm, msk = q('ATM_DOMAIN_MESH'), q('MASK_MESH')
print('atm mesh :', atm); print('mask mesh:', msk)
E.Manager(debug=False)
src_mesh = E.Mesh(filename=msk, filetype=E.FileFormat.ESMFMESH, mask_flag=E.MeshLoc.ELEMENT, varname='elementMask')
dst_mesh = E.Mesh(filename=atm, filetype=E.FileFormat.ESMFMESH)
src = E.Field(src_mesh, meshloc=E.MeshLoc.ELEMENT); dst = E.Field(dst_mesh, meshloc=E.MeshLoc.ELEMENT)
src.data[...] = src_mesh.mask[E.MeshLoc.ELEMENT]
rh = E.Regrid(src, dst, src_mask_values=np.array([0], dtype=np.int32), regrid_method=E.RegridMethod.CONSERVE,
              norm_type=E.NormType.DSTAREA, unmapped_action=E.UnmappedAction.IGNORE, ignore_degenerate=True,
              factors=True)
fl, fil = rh.get_factors()
fl = np.array(fl, np.float64); fil = np.array(fil)
rh.destroy()
n = dst.data.size
ocn = np.zeros(n)
for d in range(1, n + 1):                      # SRCSEQ: add each element's weights in source order
    sel = fil[:, 1] == d
    for s, w in sorted(zip(fil[sel, 0], fl[sel])):
        ocn[d - 1] += w
lnd = 1.0 - ocn
lnd[lnd > 1.0] = 1.0
lnd[lnd < 0.001] = 0.0
from netCDF4 import Dataset                    # element centers (degrees) from the mesh file
with Dataset(atm) as d:
    cc = np.asarray(d['centerCoords'][:], np.float64)
lon, lat = cc[:, 0], cc[:, 1]
mixed = np.where((lnd > 0.0) & (lnd < 1.0))[0]
print('elements: %d   all ocean: %d   all land: %d   mixed: %d' %
      (n, int(np.sum(lnd == 0)), int(np.sum(lnd == 1)), mixed.size))
print('  elem      lat       lon     land frac   (* = poleward of 50, sea-ice candidate in January)')
for i in sorted(mixed, key=lambda i: -abs(lat[i])):
    print('  %5d  %8.3f  %8.3f   %.6f %s' % (i + 1, lat[i], lon[i], lnd[i], '*' if abs(lat[i]) > 50 else ''))
