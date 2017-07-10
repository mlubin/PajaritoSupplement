#!/bin/bash
# runs the portfolio MICP problems with Pajarito
# run from PajaritoSupplement directory

# set julia binary location
JULIA = /home/coey/julia-903644385b/bin/julia

## SOC
for SOLVER in Port_noconic Port_MOSEK Port_MOSEK_nosep
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/micptests/soc/ instancesets/micp_soc.txt
done
mkdir out_micp_soc
mv output/* out_micp_soc

## SOC, PSD
for SOLVER in Port_noconic Port_MOSEK Port_MOSEK_nosep
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/micptests/socpsd/ instancesets/micp_socpsd.txt
done
mkdir out_micp_socpsd
mv output/* out_micp_socpsd

## SOC, EXP
for SOLVER in Port_noconic Port_ECOS Port_ECOS_nosep
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/micptests/socexp/ instancesets/micp_socexp.txt
done
mkdir out_micp_socexp
mv output/* out_micp_socexp

## SOC, EXP, PSD
for SOLVER in Port_noconic Port_SCS_warm Port_SCS_nowarm Port_SCS_warm_nosep Port_SCS_nowarm_nosep
do
    $JULIA scripts/runmeta.jl $SOLVER 3600 50000000 instancedata/micptests/socexppsd/ instancesets/micp_socexppsd.txt
done
mkdir out_micp_socexppsd
mv output/* out_micp_socexppsd
