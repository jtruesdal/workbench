# Handoff: "fast" input-data mirrors on Izumi and Derecho (from the stormspeed chat, 2026-11-13)

**Why**: many CAM input files (all CMIP6 emission files, ndep, solar, DMS, ...) are classic netCDF with an UNLIMITED
time dimension, so the time coordinate is stored interleaved with the data. `tracer_data` reads each file's whole time
axis at initialization, which touches the entire file (~700 MB for a typical emission file). On Izumi's `nfs-fs` that
costs ~100 s per file uncached. `nccopy -u` rewrites a file with fixed-size dimensions (identical data, contiguous
variables), and the time axis then reads in a few hundredths of a second.

**Where**:
- Izumi: `/project/amp/jet/inputdata_fast` (mirror of `/fs/cgd/csm/inputdata`)
- Derecho: `/glade/campaign/cgd/amp/jet/inputdata_fast` (mirror of `/glade/campaign/cesm/cesmdata/inputdata`)

Each is a tree of symbolic links to the central input data, except for **47 converted files** (about 60 GB): the
classic files with an UNLIMITED dimension named in the `atm_in` of
`SMS_D_Ln9.ne3pg3_ne3pg3_mt232.FHISTC_LTso.<mach>_intel.cam-outfrq9s_thetal` (40 CMIP6 emission files, ndep, solar,
DMS ocean concentrations, dry deposition, and a few small ones). Every other file resolves through its link, unchanged.
The lists used: Izumi `~/ss_tools/fastroot/atm_files.txt`, Derecho `~/ss_tools/atm_files_derecho.txt`.

**Use**: `./xmlchange DIN_LOC_ROOT=<mirror>` in a case, or `create_test ... --input-dir <mirror>`. Answers are identical
(BASELINE PASS on both machines).

**Measured** (Intel debug, that test): Izumi RUN 4,124 s -> 248 s; Derecho CAM initialization 94 s -> 25 s
(RUN 235 -> 166 s).

**Coverage**: only files of that configuration are converted. A SCAM case with a different compset or forcing years
(e.g. F2000climo) may read other emission files, which then work through the links at the old speed. To add them:
list the input files from the case's `CaseDocs/atm_in` and rerun the script; it converts only what's new and keeps
what's there (tcsh-safe):

    sed "s/'/ /g" CaseDocs/atm_in | grep -o "<DIN_LOC_ROOT>/[^ ]*\.nc" | sort -u > list.txt
    bash ~/ss_tools/fastroot/mk_fastroot.sh list.txt <DIN_LOC_ROOT> <mirror>

Izumi: as a one-core batch job, serially (`nfs-fs` is slow and shared); Izumi has the serial `mk_fastroot.sh`
(md5 e5f7c938...). Derecho: in `qcmd`, with `PAR=4` in front for four files at a time (parallel version, md5 f73a43b8...).
Both in `~/ss_tools/fastroot/`.

**Cautions**: if a case needs a file missing everywhere, CIME tries to download it into `DIN_LOC_ROOT`; inside a linked
directory that would mean writing into the central input data, which fails (no permission). CTSM still interpolates
its initial file at every start (`init_interp`, ~15 s Derecho, ~30 s Izumi); that is separate (input-stash item).

**Relation to the input stash**: the time-subsetted stash files (`/glade/campaign/cgd/amp/jet/scam_stash/f2000_cyc2000`
on Derecho, `/project/amp/jet/scam_stash/f2000_cyc2000` on Izumi, used via `user_nl_cam.stash`) are even smaller and are
named explicitly in `user_nl_cam`, so they take precedence over the mirror for the files they cover. The two combine:
the mirror for everything else.
