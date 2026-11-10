#!/bin/bash
# case_build.sh CASEROOT -- build a case (run through qcmd):
#   qcmd -l walltime=1:00:00 -- bash ~/ss_tools/case_build.sh /path/to/case >& log &
c=${1:?usage: case_build.sh CASEROOT}
exec "$c/case.build" "$c"
