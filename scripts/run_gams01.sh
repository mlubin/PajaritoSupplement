#!/bin/bash
# run from PajaritoSupplement directory

# set julia binary location
JULIA=/home/coey/julia-d386e40c17/bin/julia


mkdir -p output
mkdir -p output/gams01


for SOLVER in gams01_msd gams01_socinmip_msd
do
    $JULIA scripts/runmeta.jl --nochecktimemem $SOLVER 86400 40000000 cbfs/micp/ sets/gams01.txt
done

mv output/*.gams01.txt output/gams01
