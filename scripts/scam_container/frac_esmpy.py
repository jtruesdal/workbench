#!/usr/bin/env python3
"""frac_esmpy.py [MASKMESH DSTMESH [ELEM ...]]
Ocean fraction of chosen destination elements, computed the way DOCN (dshr_set_modelmask) and CTSM
(lnd_set_lndmask_from_maskmesh) do: source field = the mask mesh's elementMask (ocean 1, land 0),
source mask value 0 excluded, conservative regrid, DSTAREA normalization; srcTermProcessing=0 with
TERMORDER_SRCSEQ means the result is the sum of the weights of the unmasked source cells, added in
increasing source-index order.  So this script takes the weights themselves (factors=True), and adds
them in that order.  Run it on 1 and on N processes: if the weights or sums change, the mapping depends
on the decomposition.
Elements are 1-based (as in the CMEPS log).  Defaults: Manus 20378, Darwin 11058, Barrow 46133.
"""
import sys
import numpy as np
try:
    import esmpy as E
except ImportError:
    import ESMF as E

MASK = '/glade/campaign/cesm/cesmdata/inputdata/share/meshes/gx1v7_151008_ESMFmesh.nc'
DST = '/glade/campaign/cesm/cesmdata/inputdata/share/meshes/ne30np4_ESMFmesh_cdf5_c20211018.nc'
REF = {20378: ('Manus', 0.0), 11058: ('Darwin', 0.6334915428819583), 46133: ('Barrow', 0.35071941973255405)}

args = sys.argv[1:]
maskf = args[0] if len(args) > 0 else MASK
dstf = args[1] if len(args) > 1 else DST
elems = [int(x) for x in args[2:]] or sorted(REF)

mgr = E.Manager(debug=False)
pet, npet = mgr.local_pet, mgr.pet_count
if pet == 0:
    print('esmpy', getattr(E, '__version__', '?'), ' processes:', npet)
    print('mask mesh:', maskf)
    print('dst  mesh:', dstf)

srcmesh = E.Mesh(filename=maskf, filetype=E.FileFormat.ESMFMESH,
                 mask_flag=E.MeshLoc.ELEMENT, varname='elementMask')
dstmesh = E.Mesh(filename=dstf, filetype=E.FileFormat.ESMFMESH)
src = E.Field(srcmesh, name='mask', meshloc=E.MeshLoc.ELEMENT)
dst = E.Field(dstmesh, name='frac', meshloc=E.MeshLoc.ELEMENT)
src.data[...] = srcmesh.mask[E.MeshLoc.ELEMENT]
dst.data[...] = 0.0

rh = E.Regrid(src, dst, src_mask_values=np.array([0], dtype=np.int32),
              regrid_method=E.RegridMethod.CONSERVE, norm_type=E.NormType.DSTAREA,
              unmapped_action=E.UnmappedAction.IGNORE, ignore_degenerate=True, factors=True)
fl, fil = rh.get_factors()            # weights, and (src, dst) 1-based sequence indices
fl = np.array(fl, dtype=np.float64).copy()
fil = np.array(fil).copy()
rh.destroy()

want = np.isin(fil[:, 1], elems)
mine = [(int(s), int(d), float(w)) for (s, d), w in zip(fil[want], fl[want])]
if npet > 1:
    from mpi4py import MPI
    allp = MPI.COMM_WORLD.gather(mine, root=0)
    mine = [t for part in allp for t in part] if pet == 0 else []

if pet == 0:
    for e in elems:
        terms = sorted((s, w) for s, d, w in mine if d == e)
        ofrac = 0.0
        for s, w in terms:          # SRCSEQ: increasing source index, left to right
            ofrac += w
        lfrac = 1.0 - ofrac
        lfrac = 1.0 if lfrac > 1.0 else (0.0 if lfrac < 0.001 else lfrac)
        name, ref = REF.get(e, ('elem', None))
        print('\n== %s element %d: %d source terms' % (name, e, len(terms)))
        for s, w in terms:
            print('   src %7d  w = %r' % (s, w))
        print('   ocean fraction (sum) = %r' % ofrac)
        print('   land fraction        = %r' % lfrac, end='')
        if ref is not None:
            print('   3D run: %r  %s' % (ref, 'SAME' if lfrac == ref else 'DIFFERENT'))
        else:
            print()
