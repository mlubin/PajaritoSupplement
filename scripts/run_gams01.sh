#!/bin/bash
# run from PajaritoSupplement directory

# set julia binary location
JULIA=/home/coey/julia-d386e40c17/bin/julia


mkdir -p output
mkdir -p output/gams01


for SOLVER in PAJ_Gurobi_MOSEK_msd PAJ_Gurobi_MOSEK_msd_socinmip PAJ_Gurobi_msd_sep
do
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 86400 40000000 cbfs/micp/ sets/gams01.txt
done

mv output/*.gams01.txt output/gams01
