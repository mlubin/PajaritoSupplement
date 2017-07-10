#!/bin/bash
# runs the continuous conic problems with conic solvers
# run from PajaritoSupplement directory

# set julia binary location
JULIA = /home/coey/julia-903644385b/bin/julia

## SOC
for SOLVER in MOSEK ECOS SCS
do
    $JULIA scripts/runmeta.jl $SOLVER 300 50000000 instancedata/conttests/soc/ instancesets/cont_soc.txt
done
mkdir out_cont_soc
mv output/* out_cont_soc

## SOC, PSD
for SOLVER in MOSEK SCS
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/conttests/socpsd/ instancesets/cont_socpsd.txt
done
mkdir out_cont_socpsd
mv output/* out_cont_socpsd

## SOC, EXP
for SOLVER in ECOS SCS
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/conttests/socexp/ instancesets/cont_socexp.txt
done
mkdir out_cont_socexp
mv output/* out_cont_socexp

## SOC, EXP, PSD
for SOLVER in SCS
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/conttests/socexppsd/ instancesets/cont_socexppsd.txt
done
mkdir out_cont_socexppsd
mv output/* out_cont_socexppsd





# $JULIA scripts/runmeta.jl MOSEK 300 50000000 instancedata/conttests/soc/ instancesets/contport_soc.txt
# $JULIA scripts/runmeta.jl ECOS 300 50000000 instancedata/conttests/soc/ instancesets/contport_soc.txt
# $JULIA scripts/runmeta.jl SCS 300 50000000 instancedata/conttests/soc/ instancesets/contport_soc.txt
#
# $JULIA scripts/runmeta.jl MOSEK 300 50000000 instancedata/conttests/socpsd/ instancesets/contport_socpsd.txt
# $JULIA scripts/runmeta.jl SCS 300 50000000 instancedata/conttests/socpsd/ instancesets/contport_socpsd.txt
#
# $JULIA scripts/runmeta.jl ECOS 300 50000000 instancedata/conttests/socexp/ instancesets/contport_socexp.txt
# $JULIA scripts/runmeta.jl SCS 300 50000000 instancedata/conttests/socexp/ instancesets/contport_socexp.txt
#
# $JULIA scripts/runmeta.jl SCS 300 50000000 instancedata/conttests/socexppsd/ instancesets/contport_socexppsd.txt
